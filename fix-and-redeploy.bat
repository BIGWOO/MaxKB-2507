@echo off
chcp 65001
echo =================================
echo 修復換行符問題並重新部署
echo =================================

set CONTAINER_NAME=maxkb-mindup
set IMAGE_NAME=maxkb-local

echo 停止並刪除現有容器...
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

echo 刪除舊鏡像...
docker rmi %IMAGE_NAME% >nul 2>&1

echo.
echo =================================
echo 重新構建前端...
echo =================================
cd ui
call npm run build
if errorlevel 1 (
    echo 錯誤：前端構建失敗
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo =================================
echo 重新構建 Docker 鏡像...
echo =================================
docker build -f installer/Dockerfile -t %IMAGE_NAME% .
if errorlevel 1 (
    echo 錯誤：Docker 鏡像構建失敗
    pause
    exit /b 1
)

echo.
echo =================================
echo 啟動新容器...
echo =================================
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
echo 修復完成，重新部署成功！
echo =================================
echo 容器名稱: %CONTAINER_NAME%
echo 訪問地址: http://localhost:8080
echo.

echo 等待服務啟動...
timeout /t 15 /nobreak >nul

echo 檢查容器狀態...
docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo 檢查服務狀態...
curl -s http://localhost:8080 >nul 2>&1
if not errorlevel 1 (
    echo ✓ 服務已正常啟動
    start http://localhost:8080
) else (
    echo ! 服務可能還在啟動中，請檢查日誌
    echo   使用命令: docker logs %CONTAINER_NAME%
)

echo.
pause