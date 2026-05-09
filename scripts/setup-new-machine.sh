#!/bin/bash
# 新机器设置脚本
# 在新机器上设置Hermes环境

set -e

echo "开始设置新机器上的Hermes环境..."

# 1. 安装依赖
echo "安装系统依赖..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv git curl wget

# 2. 安装Hermes
echo "安装Hermes..."
pip3 install hermes-agent

# 3. 创建目录结构
echo "创建目录结构..."
mkdir -p ~/.hermes/{skills,cache,audio_cache,checkpoints,hooks}

# 4. 从备份恢复
echo "从备份恢复配置..."
BACKUP_DIR="$HOME/hermes-memory-project"
HERMES_DIR="$HOME/.hermes"

if [ -d "$BACKUP_DIR/skills" ]; then
    cp -r "$BACKUP_DIR/skills/"* "$HERMES_DIR/skills/"
fi

# 5. 创建配置文件
echo "创建配置文件..."
cat > ~/.hermes/config.yaml << 'CONFIGEOF'
model:
  default: mimo-v2-pro
  provider: xiaomi
  base_url: https://token-plan-cn.xiaomimimo.com/anthropic
providers: {}
fallback_providers: []
toolsets:
- hermes-cli
agent:
  max_turns: 90
  gateway_timeout: 1800
  restart_drain_timeout: 60
  service_tier: ''
  tool_use_enforcement: auto
  gateway_timeout_warning: 900
  gateway_notify_interval: 600
  verbose: false
  reasoning_effort: medium
terminal:
  backend: local
  modal_mode: auto
  timeout: 180
  auto_source_bashrc: true
CONFIGEOF

echo "设置完成！"
echo "请根据需要修改 ~/.hermes/config.yaml 中的配置。"
