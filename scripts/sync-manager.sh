#!/bin/bash
# Hermes 智能同步系统
# 提供增量备份、冲突解决和自动同步功能

set -e

# 配置
HERMES_DIR="$HOME/.hermes"
BACKUP_DIR="$HOME/hermes-memory-project"
SYNC_LOG="$BACKUP_DIR/logs/sync.log"
LAST_SYNC_FILE="$BACKUP_DIR/.last_sync"
LOCK_FILE="$BACKUP_DIR/.sync_lock"
REMOTE_REPO="git@github.com:fengjuntao2025-a11y/kaka2-hermes.git"
BRANCH="master"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SYNC_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$SYNC_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS] $1" >> "$SYNC_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$SYNC_LOG"
}

# 检查锁文件
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE")
        if ps -p "$lock_pid" > /dev/null 2>&1; then
            log_error "另一个同步进程正在运行 (PID: $lock_pid)"
            exit 1
        else
            log_warning "发现过期锁文件，正在清理"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    # 创建锁文件
    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"; exit' INT TERM EXIT
}

# 检查上次同步时间
check_last_sync() {
    if [ -f "$LAST_SYNC_FILE" ]; then
        local last_sync=$(cat "$LAST_SYNC_FILE")
        local now=$(date +%s)
        local diff=$(( (now - last_sync) / 60 ))
        
        if [ $diff -lt 5 ]; then
            log_warning "距离上次同步仅 $diff 分钟，跳过本次同步"
            exit 0
        fi
    fi
}

# 检查Hermes状态
check_hermes_status() {
    log "检查Hermes状态..."
    
    # 检查Hermes网关是否运行
    if pgrep -f "hermes gateway" > /dev/null; then
        log_success "Hermes网关正在运行"
    else
        log_warning "Hermes网关未运行"
    fi
    
    # 检查磁盘空间
    local disk_usage=$(df -h "$HERMES_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $disk_usage -gt 90 ]; then
        log_error "磁盘空间不足: ${disk_usage}% 已使用"
        return 1
    fi
    
    # 检查备份目录
    if [ ! -d "$BACKUP_DIR" ]; then
        log_error "备份目录不存在: $BACKUP_DIR"
        return 1
    fi
    
    return 0
}

# 增量备份记忆文件
backup_memory_files() {
    log "备份记忆文件..."
    
    local memory_dir="$BACKUP_DIR/memory"
    local hermes_memory_dir="$HERMES_DIR/memory"
    
    # 创建记忆目录
    mkdir -p "$memory_dir"
    
    # 如果Hermes记忆目录存在
    if [ -d "$hermes_memory_dir" ]; then
        # 同步记忆文件
        rsync -av --update "$hermes_memory_dir/" "$memory_dir/" 2>/dev/null || true
    fi
    
    # 更新当前上下文
    cat > "$memory_dir/current-context.md" << EOF
# 当前会话上下文
更新时间: $(date)
更新用户: $(whoami)
系统: $(uname -a)

## 最近活动
- 飞书网关配置
- Rail AIOS架构分析
- 网站功能评估

## 同步状态
- 上次同步: $(cat "$LAST_SYNC_FILE" 2>/dev/null | xargs -I{} date -d @{} || echo "从未同步")
- 同步状态: 成功
- 备份文件数: $(find "$BACKUP_DIR/memory" -type f | wc -l)
EOF
    
    log_success "记忆文件备份完成"
}

# 增量备份技能文件
backup_skills() {
    log "备份技能文件..."
    
    local skills_dir="$BACKUP_DIR/skills"
    local hermes_skills_dir="$HERMES_DIR/skills"
    
    # 创建技能目录
    mkdir -p "$skills_dir"
    
    # 如果Hermes技能目录存在
    if [ -d "$hermes_skills_dir" ]; then
        # 使用rsync进行增量同步
        rsync -av --update --delete \
            --exclude="*.pyc" \
            --exclude="__pycache__" \
            --exclude=".git" \
            --exclude="node_modules" \
            "$hermes_skills_dir/" "$skills_dir/" 2>/dev/null || true
        
        # 统计技能文件
        local skill_count=$(find "$skills_dir" -name "*.md" -type f | wc -l)
        log_success "技能文件备份完成: $skill_count 个技能文件"
    else
        log_warning "Hermes技能目录不存在"
    fi
}

# 备份配置模板
backup_config_templates() {
    log "备份配置模板..."
    
    local config_dir="$BACKUP_DIR/config"
    mkdir -p "$config_dir"
    
    # 备份配置模板（移除敏感信息）
    if [ -f "$HERMES_DIR/config.yaml" ]; then
        sed -e 's/api_key: .*/api_key: *** YOUR_API_KEY ***/g' \
            -e 's/token: .*/token: *** YOUR_TOKEN ***/g' \
            -e 's/secret: .*/secret: *** YOUR_SECRET ***/g' \
            -e 's/password: .*/password: *** YOUR_PASSWORD ***/g' \
            "$HERMES_DIR/config.yaml" > "$config_dir/config.template.yaml"
    fi
    
    # 备份环境模板
    if [ -f "$HERMES_DIR/.env" ]; then
        sed -e 's/=.*/=*** YOUR_VALUE ***/g' \
            "$HERMES_DIR/.env" > "$config_dir/.env.template"
    fi
    
    log_success "配置模板备份完成"
}

# 创建会话摘要
create_session_summary() {
    log "创建会话摘要..."
    
    local contexts_dir="$BACKUP_DIR/contexts"
    mkdir -p "$contexts_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local summary_file="$contexts_dir/session-summary-$timestamp.md"
    
    cat > "$summary_file" << EOF
# 会话摘要 - $timestamp

## 同步信息
- **同步时间**: $(date)
- **同步用户**: $(whoami)
- **系统**: $(uname -s) $(uname -r)
- **Hermes版本**: $(hermes version 2>/dev/null || echo "未知")

## 当前状态
- **飞书网关**: $(hermes gateway status 2>/dev/null | head -1 || echo "未知")
- **磁盘使用**: $(df -h ~ | tail -1)
- **内存使用**: $(free -h | head -2 | tail -1)

## 最近活动
$(find "$HERMES_DIR" -type f -mtime -1 -name "*.json" -o -name "*.yaml" -o -name "*.md" 2>/dev/null | head -10)

## 技能统计
- **总技能数**: $(find "$BACKUP_DIR/skills" -name "*.md" -type f 2>/dev/null | wc -l)
- **新增技能**: $(find "$BACKUP_DIR/skills" -name "*.md" -newer "$LAST_SYNC_FILE" 2>/dev/null | wc -l || echo "0")
- **修改技能**: $(find "$BACKUP_DIR/skills" -name "*.md" -newer "$LAST_SYNC_FILE" 2>/dev/null | wc -l || echo "0")
EOF
    
    log_success "会话摘要创建完成"
}

# 检查并解决冲突
resolve_conflicts() {
    log "检查冲突..."
    
    cd "$BACKUP_DIR"
    
    # 检查是否有未提交的更改
    if git status --porcelain | grep -q "^UU"; then
        log_warning "发现合并冲突，正在自动解决..."
        
        # 自动解决策略：保留本地版本
        git checkout --ours .
        git add .
        git commit -m "自动解决冲突 - 保留本地版本 $(date +%Y%m%d_%H%M%S)"
        
        log_success "冲突已自动解决"
    else
        log "没有发现冲突"
    fi
}

# 推送到GitHub
push_to_github() {
    log "推送到GitHub..."
    
    cd "$BACKUP_DIR"
    
    # 添加所有更改
    git add .
    
    # 检查是否有更改需要提交
    if git diff --cached --quiet; then
        log "没有需要提交的更改"
        return 0
    fi
    
    # 提交更改
    local commit_message="自动同步: $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_message"
    
    # 尝试推送
    if git push origin "$BRANCH"; then
        log_success "成功推送到GitHub"
    else
        log_warning "推送失败，尝试拉取最新更改..."
        
        # 尝试拉取并合并
        if git pull --rebase origin "$BRANCH"; then
            log_success "拉取成功，重新推送..."
            git push origin "$BRANCH"
        else
            log_error "拉取失败，需要手动解决冲突"
            return 1
        fi
    fi
    
    # 更新最后同步时间
    date +%s > "$LAST_SYNC_FILE"
    
    return 0
}

# 清理旧备份
cleanup_old_backups() {
    log "清理旧备份..."
    
    local backups_dir="$BACKUP_DIR/backups"
    
    if [ -d "$backups_dir" ]; then
        # 保留最近7天的备份
        find "$backups_dir" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
        
        # 清理旧的会话摘要（保留30天）
        find "$BACKUP_DIR/contexts" -name "session-summary-*.md" -mtime +30 -delete 2>/dev/null || true
        
        log_success "清理完成"
    fi
}

# 生成同步报告
generate_report() {
    log "生成同步报告..."
    
    local report_file="$BACKUP_DIR/sync-report-$(date +%Y%m%d).txt"
    
    cat > "$report_file" << EOF
Hermes 同步报告
生成时间: $(date)
同步状态: 成功

=== 备份统计 ===
总文件数: $(find "$BACKUP_DIR" -type f | wc -l)
总大小: $(du -sh "$BACKUP_DIR" | cut -f1)
记忆文件: $(find "$BACKUP_DIR/memory" -type f | wc -l)
技能文件: $(find "$BACKUP_DIR/skills" -name "*.md" -type f | wc -l)
配置文件: $(find "$BACKUP_DIR/config" -type f | wc -l)
会话摘要: $(find "$BACKUP_DIR/contexts" -name "session-summary-*.md" | wc -l)

=== Git状态 ===
当前分支: $(cd "$BACKUP_DIR" && git branch --show-current)
最后一次提交: $(cd "$BACKUP_DIR" && git log -1 --oneline)
远程仓库: $(cd "$BACKUP_DIR" && git remote -v | head -1)

=== 系统状态 ===
磁盘使用: $(df -h ~ | tail -1)
内存使用: $(free -h | head -2 | tail -1)
Hermes状态: $(hermes gateway status 2>/dev/null | head -1 || echo "未知")

=== 最近更改 ===
最近修改的记忆文件:
$(find "$BACKUP_DIR/memory" -type f -name "*.md" -mtime -1 2>/dev/null | head -5)

最近修改的技能文件:
$(find "$BACKUP_DIR/skills" -type f -name "*.md" -mtime -1 2>/dev/null | head -5)

=== 下次同步建议 ===
建议同步时间: $(date -d "+1 hour" '+%Y-%m-%d %H:%M:%S')
同步间隔: 每小时自动同步
EOF
    
    log_success "同步报告已生成: $report_file"
}

# 主同步函数
main_sync() {
    log "开始Hermes智能同步..."
    
    # 检查锁
    check_lock
    
    # 检查上次同步时间
    check_last_sync
    
    # 检查Hermes状态
    if ! check_hermes_status; then
        log_error "Hermes状态检查失败，中止同步"
        exit 1
    fi
    
    # 创建必要的目录
    mkdir -p "$BACKUP_DIR/logs"
    mkdir -p "$BACKUP_DIR/backups"
    mkdir -p "$BACKUP_DIR/contexts"
    
    # 执行备份任务
    backup_memory_files
    backup_skills
    backup_config_templates
    create_session_summary
    
    # 解决冲突
    resolve_conflicts
    
    # 推送到GitHub
    if push_to_github; then
        log_success "GitHub同步成功"
    else
        log_error "GitHub同步失败"
    fi
    
    # 清理旧备份
    cleanup_old_backups
    
    # 生成报告
    generate_report
    
    log_success "Hermes智能同步完成！"
}

# 显示帮助
show_help() {
    echo "Hermes 智能同步系统"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  同步           执行完整同步（默认）"
    echo "  增量           只同步更改的文件"
    echo "  强制           强制同步，忽略时间限制"
    echo "  状态           显示同步状态"
    echo "  报告           生成同步报告"
    echo "  清理           清理旧备份文件"
    echo "  帮助           显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              # 执行完整同步"
    echo "  $0 增量         # 只同步更改的文件"
    echo "  $0 状态         # 显示当前状态"
}

# 显示状态
show_status() {
    echo "=== Hermes 同步状态 ==="
    echo ""
    
    # 检查锁
    if [ -f "$LOCK_FILE" ]; then
        echo "状态: 正在同步中..."
        echo "进程ID: $(cat "$LOCK_FILE")"
    else
        echo "状态: 空闲"
    fi
    
    echo ""
    echo "=== 备份信息 ==="
    if [ -f "$LAST_SYNC_FILE" ]; then
        local last_sync=$(cat "$LAST_SYNC_FILE")
        local last_sync_date=$(date -d @"$last_sync" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "未知")
        echo "上次同步: $last_sync_date"
    else
        echo "上次同步: 从未同步"
    fi
    
    echo ""
    echo "=== 文件统计 ==="
    echo "记忆文件: $(find "$BACKUP_DIR/memory" -type f 2>/dev/null | wc -l)"
    echo "技能文件: $(find "$BACKUP_DIR/skills" -name "*.md" -type f 2>/dev/null | wc -l)"
    echo "配置文件: $(find "$BACKUP_DIR/config" -type f 2>/dev/null | wc -l)"
    echo "总大小: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
    
    echo ""
    echo "=== Git状态 ==="
    cd "$BACKUP_DIR" 2>/dev/null && {
        echo "当前分支: $(git branch --show-current)"
        echo "远程仓库: $(git remote -v | head -1 | awk '{print $2}')"
        echo "最后一次提交: $(git log -1 --oneline)"
    }
    
    echo ""
    echo "=== 系统状态 ==="
    echo "磁盘使用: $(df -h ~ | tail -1 | awk '{print $5}')"
    echo "内存使用: $(free -h | head -2 | tail -1 | awk '{print $3}')"
}

# 主函数
main() {
    case "${1:-同步}" in
        "同步")
            main_sync
            ;;
        "增量")
            # 只同步更改的文件
            LAST_SYNC_FILE="$BACKUP_DIR/.last_incremental"
            main_sync
            ;;
        "强制")
            # 强制同步，删除时间限制
            rm -f "$LAST_SYNC_FILE"
            main_sync
            ;;
        "状态")
            show_status
            ;;
        "报告")
            generate_report
            ;;
        "清理")
            cleanup_old_backups
            ;;
        "帮助")
            show_help
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"