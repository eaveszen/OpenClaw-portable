@echo off
chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
set "NODE_DIR=%SCRIPT_DIR%nodejs"
set "NODE_VERSION=24.0.0"

if not exist "%NODE_DIR%\node.exe" (
    echo Downloading Node.js %NODE_VERSION%...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip' -OutFile '%SCRIPT_DIR%node.zip'}"
    echo Extracting...
    powershell -Command "& {Expand-Archive -Path '%SCRIPT_DIR%node.zip' -DestinationPath '%SCRIPT_DIR%' -Force}"
    move "%SCRIPT_DIR%node-v%NODE_VERSION%-win-x64" "%NODE_DIR%"
    del "%SCRIPT_DIR%node.zip"
    echo Node.js installed!
)

set "PATH=%NODE_DIR%;%PATH%"
set "CLAWDBOT_CONFIG_PATH=%SCRIPT_DIR%moltbot\moltbot.json"

cd /d "%SCRIPT_DIR%moltbot"

echo ==========================================
echo   Moltbot 启动选项
echo ==========================================
echo 1. 快速启动 (默认)
echo 2. 升级 Moltbot
echo 3. 重装依赖
echo 4. 配置向导
echo ==========================================
echo.

set /a COUNTDOWN=8
:COUNTDOWN_LOOP
if %COUNTDOWN% GTR 0 (
    echo|set /p="请选择 [1-4] (%COUNTDOWN%秒): "
    choice /C 1234X /N /T 1 /D X >nul 2>&1
    if errorlevel 5 (
        set /a COUNTDOWN-=1
        echo.
        goto COUNTDOWN_LOOP
    )
    set CHOICE=%ERRORLEVEL%
    echo.
    goto CHOICE_DONE
)
set CHOICE=1
echo.
:CHOICE_DONE

if %CHOICE%==2 (
    echo 升级 Moltbot...
    echo 备份配置文件...
    copy moltbot.json moltbot.json.backup >nul 2>&1
    copy .env .env.backup >nul 2>&1
    
    echo 下载最新版本...
    cd /d "%SCRIPT_DIR%"
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/moltbot/moltbot/archive/refs/heads/main.zip' -OutFile 'moltbot-latest.zip'"
    
    echo 解压并覆盖...
    powershell -Command "Expand-Archive -Path 'moltbot-latest.zip' -DestinationPath '.' -Force"
    if exist moltbot.backup rd /s /q moltbot.backup
    move moltbot moltbot.backup >nul 2>&1
    move moltbot-main moltbot
    
    echo 恢复配置文件...
    copy moltbot.backup\moltbot.json moltbot\ >nul 2>&1
    if errorlevel 1 move moltbot.json.backup moltbot\moltbot.json >nul 2>&1
    copy moltbot.backup\.env moltbot\ >nul 2>&1
    if errorlevel 1 move .env.backup moltbot\.env >nul 2>&1
    
    del moltbot-latest.zip
    
    cd /d "%SCRIPT_DIR%moltbot"
    echo 安装依赖...
    "%NODE_DIR%\npm.cmd" install
    echo 构建项目...
    set COREPACK_ENABLE_AUTO_PIN=0
    echo Y | "%NODE_DIR%\npm.cmd" run build
    echo 升级完成！请重新运行启动脚本
    pause
    exit /b 0
) else if %CHOICE%==3 (
    echo 重装依赖中...
    rd /s /q node_modules 2>nul
    rd /s /q .wwebjs_auth 2>nul
    rd /s /q .wwebjs_cache 2>nul
    del package-lock.json 2>nul
    "%NODE_DIR%\npm.cmd" install --ignore-scripts
    "%NODE_DIR%\npm.cmd" rebuild
    "%NODE_DIR%\npm.cmd" run postinstall 2>nul
    echo 重装完成，请重新运行启动脚本
    pause
    exit /b 0
) else if %CHOICE%==4 (
    echo 配置向导
    if not exist "node_modules" (
        echo Installing dependencies...
        "%NODE_DIR%\npm.cmd" install
    )
    "%NODE_DIR%\node.exe" dist\index.js onboard
    pause
    exit /b 0
) else (
    if not exist "node_modules" (
        echo 首次安装依赖...
        call "%NODE_DIR%\npm.cmd" install 2>nul
        
        if exist "patches\node-llama-cpp-prebuilt.zip" (
            if not exist "node_modules\@node-llama-cpp\win-x64\bins\win-x64\llama-addon.node" (
                echo 检测到 node-llama-cpp 构建失败，使用预编译版本...
                powershell -Command "Expand-Archive -Path 'patches\node-llama-cpp-prebuilt.zip' -DestinationPath 'node_modules' -Force"
            )
        )
        
        echo 依赖安装完成，正在启动...
        echo.
    )
)

for /f "tokens=5" %%a in ('netstat -aon ^| findstr :18789') do (
    taskkill /F /PID %%a 2>nul
)

"%NODE_DIR%\node.exe" dist\index.js gateway --port 18789

pause
