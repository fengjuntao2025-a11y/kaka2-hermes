#!/bin/bash
# Hermes Agent 备份脚本
# 用于备份当前Hermes状态到hermes-memory-project

set -e

# 配置
HERMES_DIR="$HOME/.hermes"
BACKUP_DIR="$HOME/hermes-memory-project"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "开始备份Hermes状态..."
echo "时间: $(date)"
echo "源目录: $HERMES_DIR"
echo "目标目录: $BACKUP_DIR"

# 创建备份目录结构
mkdir -p "$BACKUP_DIR/memory"
mkdir -p "$BACKUP_DIR/skills"
mkdir -p "$BACKUP_DIR/config"
mkdir -p "$BACKUP_DIR/contexts"
mkdir -p "$BACKUP_DIR/scripts"
mkdir -p "$BACKUP_DIR/backups/$TIMESTAMP"

# 1. 备份记忆文件
echo "备份记忆文件..."
if [ -f "$BACKUP_DIR/memory/user-profile.md" ]; then
    cp "$BACKUP_DIR/memory/user-profile.md" "$BACKUP_DIR/backups/$TIMESTAMP/user-profile.md.backup"
fi

# 从当前Hermes会话中提取记忆信息
cat > "$BACKUP_DIR/memory/current-context.md" << 'EOF'
# 当前会话上下文
备份时间: $(date)
备份用户: $(whoami)
系统: $(uname -a)

## 最近活动
- 飞书网关配置
- Rail AIOS架构分析
- 网站功能评估

## 待办事项
1. 完成GitHub仓库设置
2. 定期自动备份
3. 优化token使用效率
EOF

# 2. 备份技能文件（排除敏感信息）
echo "备份技能文件..."
if [ -d "$HERMES_DIR/skills" ]; then
    # 只备份.md文件，排除其他可能包含敏感信息的文件
    find "$HERMES_DIR/skills" -name "*.md" -type f | while read file; do
        # 创建相对路径
        rel_path="${file#$HERMES_DIR/skills/}"
        skill_dir="$BACKUP_DIR/skills/$(dirname "$rel_path")"
        mkdir -p "$skill_dir"
        cp "$file" "$skill_dir/"
    done
    
    # 备份技能目录结构
    find "$HERMES_DIR/skills" -type d | while read dir; do
        rel_path="${dir#$HERMES_DIR/skills/}"
        mkdir -p "$BACKUP_DIR/skills/$rel_path"
    done
fi

# 3. 备份配置模板（移除敏感信息）
echo "备份配置模板..."
if [ -f "$HERMES_DIR/config.yaml" ]; then
    # 创建配置模板，移除API密钥等敏感信息
    sed -e 's/api_key: .*/api_key: *** YOUR_API_KEY ***/g' \
        -e 's/token: .*/token: *** YOUR_TOKEN ***/g' \
        -e 's/secret: .*/secret: *** YOUR_SECRET ***/g' \
        -e 's/password: .*/password: *** YOUR_PASSWORD ***/g' \
        "$HERMES_DIR/config.yaml" > "$BACKUP_DIR/config/config.template.yaml"
fi

# 4. 备份环境模板
echo "备份环境模板..."
if [ -f "$HERMES_DIR/.env" ]; then
    # 创建环境模板，移除敏感值
    sed -e 's/=.*/=*** YOUR_VALUE ***/g' \
        "$HERMES_DIR/.env" > "$BACKUP_DIR/config/.env.template"
fi

# 5. 创建会话摘要
echo "创建会话摘要..."
cat > "$BACKUP_DIR/contexts/session-summary-$TIMESTAMP.md" << EOF
# 会话摘要 - $TIMESTAMP

## 备份信息
- **备份时间**: $(date)
- **备份用户**: $(whoami)
- **系统**: $(uname -s) $(uname -r)
- **Hermes版本**: $(hermes version 2>/dev/null || echo "未知")

## 当前状态
- **飞书网关**: $(hermes gateway status 2>/dev/null | head -1 || echo "未知")
- **磁盘使用**: $(df -h ~ | tail -1)
- **内存使用**: $(free -h | head -2 | tail -1)

## 最近文件修改
$(find "$HERMES_DIR" -type f -mtime -1 -name "*.json" -o -name "*.yaml" -o -name "*.md" 2>/dev/null | head -10)

## 技能列表
$(ls -la "$HERMES_DIR/skills/" 2>/dev/null | head -20)
EOF

# 6. 创建恢复脚本
echo "创建恢复脚本..."
cat > "$BACKUP_DIR/scripts/restore-hermes.sh" << 'EOF'
#!/bin/bash
# Hermes恢复脚本
# 从备份中恢复Hermes配置和记忆

set -e

BACKUP_DIR="$HOME/hermes-memory-project"
HERMES_DIR="$HOME/.hermes"

echo "开始恢复Hermes状态..."
echo "备份目录: $BACKUP_DIR"
echo "目标目录: $HERMES_DIR"

# 检查目录是否存在
if [ ! -d "$BACKUP_DIR" ]; then
    echo "错误: 备份目录不存在"
    exit 1
fi

# 1. 恢复技能文件
echo "恢复技能文件..."
if [ -d "$BACKUP_DIR/skills" ]; then
    cp -r "$BACKUP_DIR/skills/"* "$HERMES_DIR/skills/" 2>/dev/null || true
fi

# 2. 恢复配置模板
echo "恢复配置模板..."
if [ -f "$BACKUP_DIR/config/config.template.yaml" ]; then
    echo "配置模板已恢复到: $BACKUP_DIR/config/config.template.yaml"
    echo "请根据模板手动配置: $HERMES_DIR/config.yaml"
fi

# 3. 恢复环境模板
echo "恢复环境模板..."
if [ -f "$BACKUP_DIR/config/.env.template" ]; then then
    echo "环境模板已恢复到: $BACKUP_DIR/config/.env.template"
    echo "请根据模板手动配置: $HERMES_DIR/.env"
fi

# 4. 恢复记忆文件
echo "恢复记忆文件..."
if [ -d "$BACKUP_DIR/memory" ]; then
    echo "记忆文件已恢复到: $BACKUP_DIR/memory/"
fi

echo "恢复完成！"
echo "请根据模板文件手动配置API密钥和敏感信息。"
EOF

chmod +x "$BACKUP_DIR/scripts/restore-hermes.sh"

# 7. 创建设置脚本
echo "创建设置脚本..."
cat > "$BACKUP_DIR/scripts/setup-new-machine.sh" << 'EOF'
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
EOF

chmod +x "$BACKUP_DIR/scripts/setup-new-machine.sh"

# 8. 创建同步脚本
echo "创建同步脚本..."
cat > "$BACKUP_DIR/scripts/sync-to-hermes.sh" << 'EOF'
#!/bin/bash
# 同步脚本
# 从hermes-memory-project同步到Hermes

set -e

BACKUP_DIR="$HOME/hermes-memory-project"
HERMES_DIR="$HOME/.hermes"

echo "开始同步到Hermes..."

# 同步技能文件
if [ -d "$BACKUP_DIR/skills" ]; then
    echo "同步技能文件..."
    cp -r "$BACKUP_DIR/skills/"* "$HERMES_DIR/skills/"
fi

# 同步记忆文件
if [ -d "$BACKUP_DIR/memory" ]; then
    echo "同步记忆文件..."
    # 记忆文件保留在备份目录中，不直接复制到Hermes
    echo "记忆文件位于: $BACKUP_DIR/memory/"
fi

echo "同步完成！"
EOF

chmod +x "$BACKUP_DIR/scripts/sync-to-hermes.sh"

# 9. 添加到Git
echo "添加文件到Git..."
cd "$BACKUP_DIR"
git add .
git status

# 10. 创建提交
echo "创建Git提交..."
git commit -m "备份Hermes状态 - $TIMESTAMP

备份内容:
- 用户画像和偏好
- 环境配置信息
- 技能文件
- 配置模板
- 自动化脚本

备份时间: $(date)
备份用户: $(whoami)"

echo "备份完成！"
echo "提交信息: $(git log -1 --oneline)"
echo "备份目录: $BACKUP_DIR"
echo "时间戳: $TIMESTAMP"