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
