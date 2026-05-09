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
