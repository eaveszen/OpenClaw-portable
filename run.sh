#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_VERSION="24.0.0"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)
        case "$ARCH" in
            x86_64) NODE_PKG="node-v${NODE_VERSION}-linux-x64"; NODE_DIR="nodejs-linux-x64" ;;
            aarch64|arm64) NODE_PKG="node-v${NODE_VERSION}-linux-arm64"; NODE_DIR="nodejs-linux-arm64" ;;
            *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    Darwin*)
        case "$ARCH" in
            x86_64) NODE_PKG="node-v${NODE_VERSION}-darwin-x64"; NODE_DIR="nodejs-darwin-x64" ;;
            arm64) NODE_PKG="node-v${NODE_VERSION}-darwin-arm64"; NODE_DIR="nodejs-darwin-arm64" ;;
            *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

if [ ! -d "$SCRIPT_DIR/$NODE_DIR" ]; then
    echo "First run, downloading Node.js $NODE_VERSION for $OS $ARCH..."
    cd "$SCRIPT_DIR"
    curl -L -o "${NODE_PKG}.tar.gz" "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_PKG}.tar.gz"
    echo "Extracting..."
    tar -xzf "${NODE_PKG}.tar.gz"
    mv "${NODE_PKG}" "$NODE_DIR"
    rm "${NODE_PKG}.tar.gz"
    echo "Node.js installed!"
fi

export PATH="$SCRIPT_DIR/$NODE_DIR/bin:$PATH"
export CLAWDBOT_CONFIG_PATH="$SCRIPT_DIR/moltbot/moltbot.json"

cd "$SCRIPT_DIR/moltbot"

echo "=========================================="
echo "  Moltbot 启动选项"
echo "=========================================="
echo "1. 快速启动 (默认)"
echo "2. 升级 Moltbot"
echo "3. 重装依赖"
echo "4. 配置向导"
echo "=========================================="

CHOICE="1"
for i in {8..1}; do
    printf "\r\033[K请选择 [1-4] (%d秒): " $i
    read -t 1 -n 1 input && { CHOICE="$input"; echo ""; break; }
done
if [ -z "$input" ]; then
    echo ""
fi

case "$CHOICE" in
    2)
        echo "升级 Moltbot..."
        echo "备份配置文件..."
        cp moltbot.json moltbot.json.backup 2>/dev/null || true
        cp .env .env.backup 2>/dev/null || true
        
        echo "下载最新版本..."
        cd "$SCRIPT_DIR"
        curl -L -o moltbot-latest.tar.gz "https://github.com/moltbot/moltbot/archive/refs/heads/main.tar.gz"
        
        echo "解压并覆盖..."
        tar -xzf moltbot-latest.tar.gz
        rm -rf moltbot.backup
        mv moltbot moltbot.backup
        mv moltbot-main moltbot
        
        echo "恢复配置文件..."
        cp moltbot.backup/moltbot.json moltbot/ 2>/dev/null || mv moltbot.json.backup moltbot/moltbot.json 2>/dev/null || true
        cp moltbot.backup/.env moltbot/ 2>/dev/null || mv .env.backup moltbot/.env 2>/dev/null || true
        
        rm -f moltbot-latest.tar.gz
        
        cd "$SCRIPT_DIR/moltbot"
        echo "安装依赖..."
        npm install
        echo "构建项目..."
        export COREPACK_ENABLE_AUTO_PIN=0
        yes | npm run build 2>/dev/null || npm run build
        echo "升级完成！请重新运行启动脚本"
        exit 0
        ;;
    3)
        echo "重装依赖中..."
        rm -rf node_modules package-lock.json .wwebjs_auth .wwebjs_cache
        npm install --ignore-scripts
        npm rebuild
        npm run postinstall 2>/dev/null || true
        echo "重装完成，请重新运行启动脚本"
        exit 0
        ;;
    4)
        echo "配置向导"
        if [ ! -d "node_modules" ]; then
            echo "Installing dependencies..."
            npm install
        fi
        node dist/index.js onboard
        exit 0
        ;;
    *)
        if [ ! -d "node_modules" ]; then
            echo "首次安装依赖..."
            npm install
            
            if [ -f "patches/node-llama-cpp.tar" ] && [ ! -d "node_modules/@node-llama-cpp" ]; then
                echo "检测到 node-llama-cpp 构建失败，使用预编译版本..."
                tar -xf patches/node-llama-cpp.tar -C node_modules
            fi
            
            echo "依赖安装完成，正在启动..."
            echo ""
        fi
        ;;
esac

if command -v lsof >/dev/null 2>&1; then
    lsof -ti:18789 | xargs kill -9 2>/dev/null || true
elif command -v fuser >/dev/null 2>&1; then
    fuser -k 18789/tcp 2>/dev/null || true
fi

node dist/index.js gateway --port 18789
