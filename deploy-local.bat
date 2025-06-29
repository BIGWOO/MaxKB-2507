@echo off
chcp 65001
echo =================================
echo MaxKB 本地部署腳本
echo =================================

set CONTAINER_NAME=maxkb-mindup
set IMAGE_NAME=maxkb-local

echo 檢查 Docker Desktop 是否運行中...
docker info >nul 2>&1
if errorlevel 1 (
    echo 錯誤：Docker Desktop 未運行，請先啟動 Docker Desktop
    pause
    exit /b 1
)

echo 檢查容器是否已存在...
docker ps -a --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}" | findstr %CONTAINER_NAME% >nul
if not errorlevel 1 (
    echo 發現已存在的容器 %CONTAINER_NAME%，正在停止並刪除...
    docker stop %CONTAINER_NAME% >nul 2>&1
    docker rm %CONTAINER_NAME% >nul 2>&1
    echo 已清理舊容器
)

echo 檢查舊鏡像是否存在...
docker images %IMAGE_NAME% --format "table {{.Repository}}" | findstr %IMAGE_NAME% >nul
if not errorlevel 1 (
    echo 發現舊鏡像 %IMAGE_NAME%，正在刪除...
    docker rmi %IMAGE_NAME% >nul 2>&1
    echo 已清理舊鏡像
)

echo.
echo =================================
echo 開始構建前端...
echo =================================
cd ui
if not exist "node_modules" (
    echo 安裝前端依賴...
    call npm install
    if errorlevel 1 (
        echo 錯誤：前端依賴安裝失敗
        cd ..
        pause
        exit /b 1
    )
)

echo 構建前端生產版本...
call npm run build-only
if errorlevel 1 (
    echo 錯誤：前端構建失敗
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo =================================
echo 開始構建 Docker 鏡像...
echo =================================
echo 這可能需要幾分鐘時間，請耐心等待...

docker build -f installer/Dockerfile -t %IMAGE_NAME% .
if errorlevel 1 (
    echo 錯誤：Docker 鏡像構建失敗
    pause
    exit /b 1
)

echo.
echo =================================
echo 啟動容器...
echo =================================

:: 使用你現有的官方數據目錄
if not exist "C:\maxkb" mkdir "C:\maxkb"
if not exist "C:\python-packages" mkdir "C:\python-packages"

docker run -d ^
    --name=%CONTAINER_NAME% ^
    --restart=always ^
    -p 8080:8080 ^
    -v "C:/maxkb:/var/lib/postgresql/data" ^
    -v "C:/python-packages:/opt/maxkb/app/sandbox/python-packages" ^
    -e MAXKB_DB_NAME=maxkb ^
    -e MAXKB_DB_HOST=127.0.0.1 ^
    -e MAXKB_DB_PORT=5432 ^
    -e MAXKB_DB_USER=root ^
    -e MAXKB_DB_PASSWORD=Password123@postgres ^
    %IMAGE_NAME%

if errorlevel 1 (
    echo 錯誤：容器啟動失敗
    pause
    exit /b 1
)

echo.
echo =================================
echo 部署完成！
echo =================================
echo 容器名稱: %CONTAINER_NAME%
echo 訪問地址: http://localhost:8080
echo 預設帳號: admin
echo 預設密碼: MaxKB@123..
echo.
echo 數據目錄: C:\maxkb
echo Python 套件目錄: C:\python-packages
echo.

echo 等待服務啟動...
timeout /t 10 /nobreak >nul

echo 檢查容器狀態...
docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo =================================
echo 常用管理命令:
echo =================================
echo 查看日誌: docker logs %CONTAINER_NAME%
echo 實時日誌: docker logs -f %CONTAINER_NAME%
echo 停止容器: docker stop %CONTAINER_NAME%
echo 啟動容器: docker start %CONTAINER_NAME%
echo 重啟容器: docker restart %CONTAINER_NAME%
echo 刪除容器: docker rm -f %CONTAINER_NAME%
echo.

echo 正在檢查服務是否正常啟動...
timeout /t 5 /nobreak >nul

curl -s http://localhost:8080 >nul 2>&1
if not errorlevel 1 (
    echo ✓ 服務已正常啟動，可以訪問 http://localhost:8080
    start http://localhost:8080
) else (
    echo ! 服務可能還在啟動中，請稍後嘗試訪問或檢查日誌
    echo   使用命令: docker logs %CONTAINER_NAME%
)

echo.
pause