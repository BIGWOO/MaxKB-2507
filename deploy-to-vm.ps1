# MaxKB VM Deployment Script (PowerShell版)
param(
    [string]$SSHKey = "C:\Users\bigwo\Dropbox\Server\gce\bvg\bvg-180615.key",
    [string]$VMIp = "34.80.205.176",
    [string]$URL = "https://kb.mindupplus.com",
    [string]$VMUser = "root",
    [string]$ContainerName = "maxkb-prod",
    [string]$ImageName = "maxkb-prod",
    [string]$ImageFile = "maxkb-prod.tar"
)

Write-Host "===================================" -ForegroundColor Green
Write-Host "MaxKB VM Deployment Script (PowerShell版)" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# 檢查SSH金鑰檔案
Write-Host "檢查SSH金鑰檔案..." -ForegroundColor Yellow
if (-not (Test-Path $SSHKey)) {
    Write-Host "錯誤：找不到SSH金鑰檔案: $SSHKey" -ForegroundColor Red
    Read-Host "按任意鍵退出"
    exit 1
}

# 檢查Docker狀態
Write-Host "檢查Docker狀態..." -ForegroundColor Yellow
try {
    $null = docker info 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not running"
    }
} catch {
    Write-Host "錯誤：Docker Desktop未執行" -ForegroundColor Red
    Read-Host "按任意鍵退出"
    exit 1
}

# 檢查OpenSSH
Write-Host "檢查OpenSSH客戶端..." -ForegroundColor Yellow
try {
    $null = ssh -V 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "SSH not found"
    }
} catch {
    Write-Host "錯誤：找不到SSH命令。請安裝OpenSSH客戶端" -ForegroundColor Red
    Write-Host "安裝方法：Settings > Apps > Optional Features > Add Feature > OpenSSH Client" -ForegroundColor Yellow
    Read-Host "按任意鍵退出"
    exit 1
}

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "步驟1：本地建立Docker映像" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

Write-Host "清理舊映像..." -ForegroundColor Yellow
docker rmi "$ImageName`:latest" 2>$null | Out-Null

Write-Host "建立新映像..." -ForegroundColor Yellow
docker build -f installer/Dockerfile -t "$ImageName`:latest" .
if ($LASTEXITCODE -ne 0) {
    Write-Host "錯誤：Docker映像建立失敗" -ForegroundColor Red
    Read-Host "按任意鍵退出"
    exit 1
}

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "步驟2：匯出映像到檔案" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

Write-Host "匯出映像..." -ForegroundColor Yellow
if (Test-Path $ImageFile) { Remove-Item $ImageFile -Force }
if (Test-Path "maxkb-prod.tar") { Remove-Item "maxkb-prod.tar" -Force }

docker save "$ImageName`:latest" -o maxkb-prod.tar
if ($LASTEXITCODE -ne 0) {
    Write-Host "錯誤：映像匯出失敗" -ForegroundColor Red
    Read-Host "按任意鍵退出"
    exit 1
}

$fileSize = (Get-Item $ImageFile).Length
Write-Host "映像檔案大小: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor Green

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "步驟3：上傳映像到VM" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

Write-Host "上傳映像檔案到VM..." -ForegroundColor Yellow
scp -i "$SSHKey" -o StrictHostKeyChecking=no "$ImageFile" "${VMUser}@${VMIp}:/tmp/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "錯誤：檔案上傳失敗" -ForegroundColor Red
    Read-Host "按任意鍵退出"
    exit 1
}

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "步驟4：在VM上部署" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

Write-Host "檢查SSH連線..." -ForegroundColor Yellow
ssh -i "$SSHKey" -o StrictHostKeyChecking=no "${VMUser}@${VMIp}" "echo 'SSH連線成功'"
if ($LASTEXITCODE -ne 0) {
    Write-Host "錯誤：SSH連線失敗" -ForegroundColor Red
    Write-Host "請檢查：" -ForegroundColor Yellow
    Write-Host "1. SSH金鑰路徑: $SSHKey" -ForegroundColor Yellow
    Write-Host "2. VM IP: $VMIp" -ForegroundColor Yellow
    Write-Host "3. VM是否執行且可連線" -ForegroundColor Yellow
    Read-Host "按任意鍵退出"
    exit 1
}

Write-Host "執行VM部署腳本..." -ForegroundColor Yellow

# 直接使用單行命令，避免換行符問題
$deployCommand = "echo 'Starting VM deployment process...'; echo 'Creating persistent directories...'; mkdir -p /opt/maxkb-docker/data; mkdir -p /opt/maxkb-docker/python-packages; echo 'Checking and cleaning old containers...'; if docker ps -a --filter 'name=${ContainerName}' --format '{{.Names}}' | grep -q '${ContainerName}'; then echo 'Stopping old container...'; docker stop ${ContainerName} 2>/dev/null || true; echo 'Removing old container...'; docker rm ${ContainerName} 2>/dev/null || true; fi; echo 'Cleaning old images...'; docker rmi ${ImageName}:latest 2>/dev/null || true; echo 'Loading new image...'; cd /tmp && docker load -i ${ImageFile} && rm -f ${ImageFile}; if [ `$? -ne 0 ]; then echo 'ERROR: Image load failed'; exit 1; fi; echo 'Starting new container...'; docker run -d --name=${ContainerName} --restart=always --memory=6g --memory-swap=7g -p 8080:8080 -v /opt/maxkb-docker/data:/var/lib/postgresql/data -v /opt/maxkb-docker/python-packages:/opt/maxkb/app/sandbox/python-packages -e MAXKB_DB_NAME=maxkb -e MAXKB_DB_HOST=127.0.0.1 -e MAXKB_DB_PORT=5432 -e MAXKB_DB_USER=root -e MAXKB_DB_PASSWORD=Password123@postgres ${ImageName}:latest; if [ `$? -ne 0 ]; then echo 'ERROR: Container start failed'; exit 1; fi; echo 'Cleaning temporary files...'; rm -f /tmp/${ImageFile}; echo 'Waiting for service to start...'; sleep 10; echo 'Checking container status...'; docker ps --filter 'name=${ContainerName}' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'; echo 'Checking service status...'; if curl -s http://localhost:8080 >/dev/null 2>&1; then echo 'Service started successfully!'; else echo 'Service may still be starting, please check later'; echo 'Use command to check logs: docker logs ${ContainerName}'; fi; echo 'VM deployment completed!';"

ssh -i "$SSHKey" -o StrictHostKeyChecking=no "${VMUser}@${VMIp}" $deployCommand
if ($LASTEXITCODE -ne 0) {
    Write-Host "錯誤：VM部署失敗" -ForegroundColor Red
    Read-Host "按任意鍵退出"
    exit 1
}

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "部署完成！" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host "容器名稱：$ContainerName" -ForegroundColor Cyan
Write-Host "存取網址：http://$VMIp`:8080" -ForegroundColor Cyan
Write-Host "預設帳號：admin" -ForegroundColor Cyan
Write-Host "預設密碼：MaxKB@123.." -ForegroundColor Cyan
Write-Host ""
Write-Host "持久化目錄：" -ForegroundColor Yellow
Write-Host "  資料：/opt/maxkb-docker/data" -ForegroundColor Yellow
Write-Host "  Python套件：/opt/maxkb-docker/python-packages" -ForegroundColor Yellow
Write-Host ""
Write-Host "常用管理命令：" -ForegroundColor Yellow
Write-Host "  SSH連線：ssh -i `"$SSHKey`" $VMUser@$VMIp" -ForegroundColor Yellow
Write-Host "  檢視日誌：docker logs $ContainerName" -ForegroundColor Yellow
Write-Host "  重啟容器：docker restart $ContainerName" -ForegroundColor Yellow
Write-Host ""

Write-Host "清理本地暫存檔案..." -ForegroundColor Yellow
if (Test-Path $ImageFile) { Remove-Item $ImageFile -Force }

Write-Host "開啟瀏覽器..." -ForegroundColor Yellow
Start-Process "$URL"

Write-Host "部署完成！" -ForegroundColor Green
Read-Host "按任意鍵退出"