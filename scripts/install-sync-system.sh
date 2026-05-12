#!/bin/bash
# Hermes 同步系统安装脚本

set -e

echo "=== Hermes 同步系统安装 ==="
echo "安装时间: $(date)"
echo ""

# 配置
HERMES_DIR="$HOME/.hermes"
BACKUP_DIR="$HOME/hermes-memory-project"
CONFIG_DIR="$BACKUP_DIR/config"
SCRIPTS_DIR="$BACKUP_DIR/scripts"
LOGS_DIR="$BACKUP_DIR/logs"
SYNC_STATE_DIR="$BACKUP_DIR/.sync-state"

# 创建目录
echo "创建目录结构..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$LOGS_DIR"
mkdir -p "$SYNC_STATE_DIR"
mkdir -p "$BACKUP_DIR/backups"
mkdir -p "$BACKUP_DIR/contexts"
mkdir -p "$BACKUP_DIR/docs"

# 检查依赖
echo "检查系统依赖..."
dependencies=("git" "rsync" "curl" "jq")
missing_deps=()

for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        missing_deps+=("$dep")
        echo "  ❌ $dep: 未安装"
    else
        echo "  ✅ $dep: $(command -v "$dep")"
    fi
done

if [ ${#missing_deps[@]} -ne 0 ]; then
    echo ""
    echo "请安装缺失的依赖:"
    echo "  sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
    exit 1
fi

# 检查Git配置
echo ""
echo "检查Git配置..."
cd "$BACKUP_DIR"

if ! git remote -v | grep -q "origin"; then
    echo "  ⚠️  未找到远程仓库"
    echo "  请手动添加远程仓库:"
    echo "    git remote add origin git@github.com:username/repo.git"
else
    echo "  ✅ 远程仓库: $(git remote -v | head -1 | awk '{print $2}')"
fi

# 检查SSH密钥
echo ""
echo "检查SSH密钥..."
if ssh-add -l &> /dev/null; then
    echo "  ✅ SSH密钥: $(ssh-add -l | head -1)"
else
    echo "  ⚠️  未找到SSH密钥"
    echo "  请添加SSH密钥:"
    echo "    ssh-add ~/.ssh/id_ed25519"
fi

# 创建同步配置文件
echo ""
echo "创建同步配置..."
cat > "$CONFIG_DIR/sync-config.json" << 'EOF'
{
  "sync_interval": 3600,
  "full_sync_interval": 86400,
  "backup_retention_days": 30,
  "incremental_backup_days": 7,
  "conflict_resolution": "local_first",
  "auto_push": true,
  "push_retries": 3,
  "notification": {
    "enabled": false,
    "email": "",
    "on_success": false,
    "on_failure": true
  },
  "exclude_patterns": [
    "*.pyc",
    "__pycache__",
    "node_modules",
    ".git",
    "*.tmp",
    "*.log"
  ],
  "critical_files": [
    "memory/user-profile.md",
    "memory/environment.md",
    "config/config.template.yaml"
  ]
}
EOF

# 创建cron定时任务
echo "创建定时任务..."
cat > "$CONFIG_DIR/cron-jobs.txt" << 'EOF'
# Hermes 自动同步定时任务
# 每小时增量同步
0 * * * * cd ~/hermes-memory-project && bash scripts/sync-manager.sh 增量 >> logs/cron.log 2>&1

# 每天凌晨2点完整同步
0 2 * * * cd ~/hermes-memory-project && bash scripts/sync-manager.sh 同步 >> logs/cron.log 2>&1

# 每周日凌晨3点清理旧备份
0 3 * * 0 cd ~/hermes-memory-project && bash scripts/sync-manager.sh 清理 >> logs/cron.log 2>&1

# 每月1号生成同步报告
0 4 1 * * cd ~/hermes-memory-project && bash scripts/sync-manager.sh 报告 >> logs/cron.log 2>&1
EOF

# 设置脚本权限
echo "设置脚本权限..."
chmod +x "$SCRIPTS_DIR/sync-manager.sh"
chmod +x "$SCRIPTS_DIR/backup-hermes.sh"
chmod +x "$SCRIPTS_DIR/restore-hermes.sh"
chmod +x "$SCRIPTS_DIR/setup-new-machine.sh"
chmod +x "$SCRIPTS_DIR/sync-to-hermes.sh"

# 创建初始同步状态
echo "创建初始同步状态..."
date +%s > "$SYNC_STATE_DIR/last-sync"

# 创建守护进程脚本
echo "创建守护进程脚本..."
cat > "$SCRIPTS_DIR/sync-daemon.sh" << 'EOF'
#!/bin/bash
# Hermes 同步守护进程

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$(dirname "$SCRIPT_DIR")"
PID_FILE="$BACKUP_DIR/.sync-daemon.pid"
LOG_FILE="$BACKUP_DIR/logs/sync-daemon.log"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

check_pid() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

start_daemon() {
    if check_pid; then
        log_error "守护进程已在运行 (PID: $(cat "$PID_FILE"))"
        exit 1
    fi
    
    log "启动Hermes同步守护进程..."
    
    # 启动后台进程
    nohup bash -c "
        while true; do
            # 每小时执行一次增量同步
            bash '$SCRIPT_DIR/sync-manager.sh' 增量 >> '$LOG_FILE' 2>&1
            
            # 等待1小时
            sleep 3600
        done
    " >> "$LOG_FILE" 2>&1 &
    
    # 保存PID
    echo $! > "$PID_FILE"
    
    log "守护进程启动成功 (PID: $!)"
    log "日志文件: $LOG_FILE"
}

stop_daemon() {
    if ! check_pid; then
        log "守护进程未运行"
        return 0
    fi
    
    local pid=$(cat "$PID_FILE")
    log "停止守护进程 (PID: $pid)..."
    
    kill "$pid" 2>/dev/null && log "守护进程已停止" || log_error "无法停止守护进程"
    
    rm -f "$PID_FILE"
}

status_daemon() {
    if check_pid; then
        local pid=$(cat "$PID_FILE")
        echo "守护进程状态: 运行中 (PID: $pid)"
        echo "运行时间: $(ps -p "$pid" -o etime= | xargs)"
        echo "内存使用: $(ps -p "$pid" -o %mem= | xargs)%"
        echo "日志文件: $LOG_FILE"
        echo ""
        echo "最近日志:"
        tail -5 "$LOG_FILE" 2>/dev/null || echo "无日志"
    else
        echo "守护进程状态: 未运行"
    fi
}

case "${1:-start}" in
    "start")
        start_daemon
        ;;
    "stop")
        stop_daemon
        ;;
    "restart")
        stop_daemon
        sleep 2
        start_daemon
        ;;
    "status")
        status_daemon
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

chmod +x "$SCRIPTS_DIR/sync-daemon.sh"

# 创建监控脚本
echo "创建监控脚本..."
cat > "$SCRIPTS_DIR/monitor-sync.sh" << 'EOF'
#!/bin/bash
# Hermes 同步监控脚本

set -e

BACKUP_DIR="$HOME/hermes-memory-project"
LOG_FILE="$BACKUP_DIR/logs/monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_sync_health() {
    local health_status=0
    
    # 检查最后同步时间
    if [ -f "$BACKUP_DIR/.last_sync" ]; then
        local last_sync=$(cat "$BACKUP_DIR/.last_sync")
        local now=$(date +%s)
        local diff=$(( (now - last_sync) / 3600 ))
        
        if [ $diff -gt 24 ]; then
            log "警告: 距离上次同步已超过24小时"
            health_status=1
        fi
    else
        log "警告: 从未同步"
        health_status=1
    fi
    
    # 检查磁盘空间
    local disk_usage=$(df -h "$BACKUP_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $disk_usage -gt 90 ]; then
        log "警告: 磁盘空间不足: ${disk_usage}%"
        health_status=1
    fi
    
    # 检查Git状态
    cd "$BACKUP_DIR"
    if git status --porcelain | grep -q "UU"; then
        log "警告: 存在未解决的Git冲突"
        health_status=1
    fi
    
    return $health_status
}

generate_monitoring_report() {
    local report_file="$BACKUP_DIR/logs/monitoring-report-$(date +%Y%m%d).txt"
    
    cat > "$report_file" << EOF
Hermes 同步监控报告
生成时间: $(date)

=== 健康状态 ===
$(check_sync_health && echo "健康" || echo "存在问题")

=== 同步状态 ===
最后同步时间: $(if [ -f "$BACKUP_DIR/.last_sync" ]; then date -d @$(cat "$BACKUP_DIR/.last_sync") '+%Y-%m-%d %H:%M:%S'; else echo "从未同步"; fi)
同步守护进程: $(if [ -f "$BACKUP_DIR/.sync-daemon.pid" ]; then echo "运行中"; else echo "未运行"; fi)

=== 系统资源 ===
磁盘使用: $(df -h "$BACKUP_DIR" | tail -1 | awk '{print $5}')
内存使用: $(free -h | head -2 | tail -1 | awk '{print $3}')

=== Git状态 ===
当前分支: $(git branch --show-current)
未提交更改: $(git status --porcelain | wc -l)
未推送提交: $(git log --branches --not --remotes --oneline | wc -l)

=== 文件统计 ===
记忆文件: $(find "$BACKUP_DIR/memory" -type f | wc -l)
技能文件: $(find "$BACKUP_DIR/skills" -name "*.md" -type f | wc -l)
总大小: $(du -sh "$BACKUP_DIR" | cut -f1)
EOF
    
    echo "监控报告已生成: $report_file"
}

# 主函数
main() {
    case "${1:-检查}" in
        "检查")
            check_sync_health
            ;;
        "报告")
            generate_monitoring_report
            ;;
        *)
            echo "用法: $0 {检查|报告}"
            exit 1
            ;;
    esac
}

main "$@"
EOF

chmod +x "$SCRIPTS_DIR/monitor-sync.sh"

# 创建快捷方式
echo "创建快捷方式..."
cat > "$BACKUP_DIR/sync" << 'EOF'
#!/bin/bash
# Hermes 同步快捷方式

cd "$(dirname "$0")"
bash scripts/sync-manager.sh "$@"
EOF

chmod +x "$BACKUP_DIR/sync"

# 创建桌面快捷方式（可选）
if [ -d "$HOME/Desktop" ]; then
    cat > "$HOME/Desktop/Hermes同步.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Hermes 同步
Comment=同步Hermes Agent记忆和配置
Exec=gnome-terminal -- bash -c "cd ~/hermes-memory-project && bash scripts/sync-manager.sh 状态; read -p '按回车键关闭...'"
Icon=utilities-terminal
Terminal=false
StartupNotify=false
Categories=Utility;
EOF
    chmod +x "$HOME/Desktop/Hermes同步.desktop"
fi

# 设置自动启动（可选）
echo "设置自动启动..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/hermes-sync-daemon.desktop" << EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Hermes 同步守护进程
Comment=自动同步Hermes Agent记忆和配置
Exec=bash $SCRIPTS_DIR/sync-daemon.sh start
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# 首次运行测试
echo ""
echo "测试首次同步..."
if bash "$SCRIPTS_DIR/sync-manager.sh" 状态; then
    echo "  ✅ 同步脚本工作正常"
else
    echo "  ❌ 同步脚本测试失败"
    exit 1
fi

# 显示安装摘要
echo ""
echo "=== 安装完成 ==="
echo ""
echo "安装位置: $BACKUP_DIR"
echo ""
echo "可用命令:"
echo "  同步管理:"
echo "    ./sync 同步       # 执行完整同步"
echo "    ./sync 增量       # 执行增量同步"
echo "    ./sync 状态       # 查看同步状态"
echo "    ./sync 报告       # 生成同步报告"
echo ""
echo "  守护进程:"
echo "    bash scripts/sync-daemon.sh start    # 启动守护进程"
echo "    bash scripts/sync-daemon.sh stop     # 停止守护进程"
echo "    bash scripts/sync-daemon.sh status   # 查看守护进程状态"
echo ""
echo "  监控:"
echo "    bash scripts/monitor-sync.sh 检查   # 检查同步健康"
echo "    bash scripts/monitor-sync.sh 报告   # 生成监控报告"
echo ""
echo "定时任务:"
echo "  已创建定时任务配置: $CONFIG_DIR/cron-jobs.txt"
echo "  要安装定时任务，请运行:"
echo "    crontab $CONFIG_DIR/cron-jobs.txt"
echo ""
echo "自动启动:"
echo "  已配置守护进程自动启动"
echo "  登录时将自动启动同步守护进程"
echo ""
echo "文档:"
echo "  同步策略文档: $BACKUP_DIR/docs/SYNC-STRATEGY.md"
echo "  安装日志: $LOGS_DIR/install.log"
echo ""
echo "下一步:"
echo "  1. 检查配置文件: $CONFIG_DIR/sync-config.json"
echo "  2. 测试首次同步: ./sync 同步"
echo "  3. 启动守护进程: bash scripts/sync-daemon.sh start"
echo ""
echo "安装完成！"