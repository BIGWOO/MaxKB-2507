#!/bin/bash
#
# MaxKB v2 部署腳本 - transgene-docker VM
# 用法: ./deploy.sh [--build] [--restart] [--reset-password]
#
# 前置條件:
#   - .env 檔案（從 .env.example 複製並填入密碼）
#   - SSH 免密碼連線到 VM
#
set -e

# ============ 載入 .env ============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ 找不到 .env 檔案！請從 .env.example 複製並設定："
    echo "   cp .env.example .env && vim .env"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

for var in VM_HOST VM_REPO CONTAINER_NAME IMAGE_NAME PORT ADMIN_USER ADMIN_PASS; do
    [ -z "${!var}" ] && { echo "❌ .env 缺少 $var"; exit 1; }
done

VM_COMPOSE="/opt/maxkb-v2/docker-compose.yml"
DOMAIN="${DOMAIN:-ai.mindupplus.com}"

# 顏色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ============ 函數 ============

check_ssh() {
    log "檢查 SSH 連線..."
    ssh -o ConnectTimeout=5 "$VM_HOST" "echo ok" > /dev/null 2>&1 \
        || err "無法連線到 $VM_HOST"
    log "SSH 連線正常 ✅"
}

ensure_swap() {
    log "確認 swap（build 需要）..."
    local swap_size
    swap_size=$(ssh "$VM_HOST" "free -b | awk '/Swap/{print \$2}'")
    if [ "$swap_size" -lt 1000000000 ]; then
        warn "Swap 不足，建立 4GB swap..."
        ssh "$VM_HOST" "
            fallocate -l 4G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=4096
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
        "
        log "Swap 建立完成 ✅"
    else
        log "Swap 已存在 ✅"
    fi
}

pull_code() {
    log "更新程式碼..."
    ssh "$VM_HOST" "
        if [ -d $VM_REPO/.git ]; then
            cd $VM_REPO && git fetch origin && git reset --hard origin/main
        else
            git clone https://github.com/BIGWOO/MaxKB-2507.git $VM_REPO
        fi
    "
    local commit
    commit=$(ssh "$VM_HOST" "cd $VM_REPO && git log --oneline -1")
    log "程式碼更新完成: $commit ✅"
}

build_image() {
    log "開始 build Docker image（約 15-30 分鐘）..."
    ssh "$VM_HOST" "
        cd $VM_REPO && \
        docker build --progress=plain \
            -f installer/Dockerfile \
            -t $IMAGE_NAME . 2>&1 | tee /tmp/maxkb-build.log
    "
    local image_id
    image_id=$(ssh "$VM_HOST" "docker images -q $IMAGE_NAME")
    [ -z "$image_id" ] && err "Image build 失敗！查看: ssh $VM_HOST 'tail -50 /tmp/maxkb-build.log'"
    log "Image build 完成: $image_id ✅"
}

ensure_compose() {
    log "確認 docker-compose.yml..."
    ssh "$VM_HOST" "
        mkdir -p /opt/maxkb-v2/data /opt/maxkb-v2/python-packages
        cat > $VM_COMPOSE << COMPOSE_EOF
services:
  maxkb-v2:
    image: $IMAGE_NAME
    container_name: $CONTAINER_NAME
    restart: unless-stopped
    ports:
      - '$PORT:8080'
    volumes:
      - /opt/maxkb-v2/data:/var/lib/postgresql/17/main
      - /opt/maxkb-v2/python-packages:/opt/maxkb/app/sandbox/python-packages
    environment:
      - VITE_APP_TITLE=MindUP AI
COMPOSE_EOF
    "
    log "docker-compose.yml 就緒 ✅"
}

ensure_nginx() {
    log "確認 nginx vhost..."
    ssh "$VM_HOST" "
        if [ ! -f /etc/nginx/sites-enabled/$DOMAIN ]; then
            cat > /etc/nginx/sites-enabled/$DOMAIN << 'NGINX_EOF'
server {
    listen 80;
    server_name $DOMAIN;

    client_max_body_size 100m;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_read_timeout 300s;
    }
}
NGINX_EOF
            nginx -t && nginx -s reload
            echo 'nginx vhost 已建立'
        else
            echo 'nginx vhost 已存在'
        fi
    "
    log "Nginx 設定完成 ✅"
}

deploy_container() {
    log "部署容器..."
    ssh "$VM_HOST" "
        cd /opt/maxkb-v2
        docker compose down 2>/dev/null || true
        docker compose up -d
    "

    log "等待 MaxKB 啟動..."
    local retries=0
    while [ $retries -lt 60 ]; do
        local status
        status=$(ssh "$VM_HOST" "curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1:$PORT 2>/dev/null || echo '000'")
        if [ "$status" = "302" ] || [ "$status" = "200" ]; then
            log "MaxKB 啟動成功 (HTTP $status) ✅"
            return 0
        fi
        retries=$((retries + 1))
        sleep 5
    done
    err "MaxKB 啟動超時！檢查: ssh $VM_HOST 'docker logs $CONTAINER_NAME'"
}

reset_password() {
    log "重設 admin 密碼..."
    ssh "$VM_HOST" "docker exec $CONTAINER_NAME python3 /opt/maxkb-app/apps/manage.py shell -c \"
from common.utils.common import password_encrypt
from django.db import connection
encrypted = password_encrypt('$ADMIN_PASS')
with connection.cursor() as c:
    c.execute('UPDATE \\\"user\\\" SET password=%s WHERE username=%s', [encrypted, '$ADMIN_USER'])
    print(f'Updated {c.rowcount} row(s)')
\""
    log "密碼重設完成 ✅"
}

backup_db() {
    log "備份資料庫..."
    local backup_file="/opt/maxkb-v2/backup_$(date +%Y%m%d_%H%M%S).sql"
    ssh "$VM_HOST" "docker exec $CONTAINER_NAME pg_dump -U root maxkb > $backup_file"
    log "備份完成: $backup_file ✅"
}

show_status() {
    echo ""
    echo "=============================="
    echo " MaxKB v2 部署狀態"
    echo "=============================="
    ssh "$VM_HOST" "
        echo '容器:'
        docker ps --filter name=$CONTAINER_NAME --format '  {{.Names}} | {{.Status}} | {{.Ports}}'
        echo ''
        echo 'URL: http://$DOMAIN'
        echo '管理: http://$DOMAIN/admin/login'
        echo ''
        echo 'v1 (保留):'
        docker ps --filter name=maxkb-prod --format '  {{.Names}} | {{.Status}} | {{.Ports}}'
    "
    echo "=============================="
}

# ============ 主程式 ============

DO_BUILD=false
DO_RESTART=false
DO_RESET_PW=false
DO_BACKUP=false
DO_FULL=false

for arg in "$@"; do
    case $arg in
        --build)          DO_BUILD=true ;;
        --restart)        DO_RESTART=true ;;
        --reset-password) DO_RESET_PW=true ;;
        --backup)         DO_BACKUP=true ;;
        --full)           DO_FULL=true ;;
        --status)         check_ssh; show_status; exit 0 ;;
        --help|-h)
            echo "用法: ./deploy.sh [選項]"
            echo ""
            echo "選項:"
            echo "  --full           完整部署（pull + build + deploy + nginx）"
            echo "  --build          僅 build image"
            echo "  --restart        僅重啟容器（用現有 image）"
            echo "  --reset-password 重設 admin 密碼"
            echo "  --backup         備份資料庫"
            echo "  --status         查看部署狀態"
            echo ""
            echo "設定: 編輯 .env（從 .env.example 複製）"
            exit 0
            ;;
        *) err "未知選項: $arg（用 --help 查看說明）" ;;
    esac
done

if ! $DO_BUILD && ! $DO_RESTART && ! $DO_RESET_PW && ! $DO_BACKUP && ! $DO_FULL; then
    check_ssh; show_status; exit 0
fi

check_ssh

if $DO_FULL; then
    pull_code; ensure_swap; build_image; ensure_compose; ensure_nginx
    deploy_container; reset_password; show_status; exit 0
fi

$DO_BACKUP && backup_db
$DO_BUILD && { pull_code; ensure_swap; build_image; }
$DO_RESTART && { ensure_compose; deploy_container; }
$DO_RESET_PW && reset_password

show_status
