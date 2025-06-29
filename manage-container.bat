@echo off
chcp 65001
set CONTAINER_NAME=maxkb-mindup

:menu
cls
echo =================================
echo MaxKB 容器管理工具
echo =================================
echo 容器名稱: %CONTAINER_NAME%
echo.
echo 1. 查看容器狀態
echo 2. 啟動容器
echo 3. 停止容器
echo 4. 重啟容器
echo 5. 查看即時日誌
echo 6. 查看最近日誌
echo 7. 進入容器 Shell
echo 8. 完全清理容器和鏡像
echo 9. 開啟網頁管理介面
echo 0. 退出
echo.
set /p choice=請選擇操作 (0-9): 

if "%choice%"=="1" goto status
if "%choice%"=="2" goto start
if "%choice%"=="3" goto stop
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto logs_follow
if "%choice%"=="6" goto logs_recent
if "%choice%"=="7" goto shell
if "%choice%"=="8" goto cleanup
if "%choice%"=="9" goto open_web
if "%choice%"=="0" goto exit

echo 無效選擇，請重新選擇
timeout /t 2 /nobreak >nul
goto menu

:status
echo.
echo =================================
echo 容器狀態
echo =================================
docker ps -a --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo.
pause
goto menu

:start
echo.
echo 正在啟動容器...
docker start %CONTAINER_NAME%
if errorlevel 1 (
    echo 啟動失敗，可能容器不存在
) else (
    echo 容器已啟動
    timeout /t 3 /nobreak >nul
    echo 檢查服務狀態...
    curl -s http://localhost:8080 >nul 2>&1
    if not errorlevel 1 (
        echo ✓ 服務已可用: http://localhost:8080
    ) else (
        echo ! 服務可能還在啟動中，請稍後檢查
    )
)
echo.
pause
goto menu

:stop
echo.
echo 正在停止容器...
docker stop %CONTAINER_NAME%
if errorlevel 1 (
    echo 停止失敗，可能容器不存在或已停止
) else (
    echo 容器已停止
)
echo.
pause
goto menu

:restart
echo.
echo 正在重啟容器...
docker restart %CONTAINER_NAME%
if errorlevel 1 (
    echo 重啟失敗，可能容器不存在
) else (
    echo 容器已重啟
    echo 等待服務啟動...
    timeout /t 10 /nobreak >nul
    curl -s http://localhost:8080 >nul 2>&1
    if not errorlevel 1 (
        echo ✓ 服務已可用: http://localhost:8080
    ) else (
        echo ! 服務可能還在啟動中，請稍後檢查
    )
)
echo.
pause
goto menu

:logs_follow
echo.
echo =================================
echo 即時日誌 (按 Ctrl+C 停止)
echo =================================
docker logs -f %CONTAINER_NAME%
goto menu

:logs_recent
echo.
echo =================================
echo 最近 100 行日誌
echo =================================
docker logs --tail 100 %CONTAINER_NAME%
echo.
pause
goto menu

:shell
echo.
echo =================================
echo 進入容器 Shell (輸入 exit 退出)
echo =================================
docker exec -it %CONTAINER_NAME% /bin/bash
goto menu

:cleanup
echo.
echo =================================
echo 警告：這將完全刪除容器和本地構建的鏡像
echo =================================
set /p confirm=確定要繼續嗎？(y/N): 
if /i not "%confirm%"=="y" goto menu

echo 停止並刪除容器...
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

echo 刪除本地鏡像...
docker rmi maxkb-local >nul 2>&1

echo 清理完成！
echo 注意：數據目錄 C:\maxkb 仍然保留
echo.
pause
goto menu

:open_web
echo.
echo 正在開啟網頁管理介面...
start http://localhost:8080
goto menu

:exit
echo 再見！
exit /b 0