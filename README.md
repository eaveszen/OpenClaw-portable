# Moltbot Cross-Platform Portable

[中文版](README_CN.md) | English

No installation required, supports Windows / Linux / macOS one-click run!

![cmd.png](cmd.png)

Windows: Double-click `run.bat` 
Linux / macOS: chmod +x run.sh && ./run.sh

Node.js and dependencies will be downloaded automatically on first run.

## ⚠️ First-time Setup Required

### 1. Edit configuration file `moltbot/moltbot.json`

**Must modify the following sensitive information (otherwise it won't work):**

- **Line 7** `apiKey`: Replace with your Nvidia API Key (get from https://build.nvidia.com/settings/api-keys)
- **Line 60** `botToken`: Replace with your Telegram Bot Token (get from @BotFather)
- **Line 62** `allowFrom`: Replace with your Telegram User ID (get from @userinfobot)
- **Line 66** `proxy`: Replace with your Telegram proxy address (optional)

## Configuration Files
- **API Key environment variables**: `moltbot/.env`
- **Custom model configuration**: `moltbot/moltbot.json`

Official site: https://molt.bot/
