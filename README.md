# Hermes Agent 记忆与上下文仓库

这个仓库用于存储Hermes Agent的自我进化信息，包括记忆、配置、技能和对话上下文。

## 目录结构

```
hermes-memory-project/
├── memory/          # Agent记忆文件
├── skills/          # 自定义技能
├── config/          # 配置文件模板（不含敏感信息）
├── scripts/         # 自动化脚本
├── contexts/        # 对话上下文摘要
└── README.md        # 本说明文件
```

## 内容说明

### 1. 记忆文件
- `memory/user-profile.md` - 用户画像和偏好
- `memory/environment.md` - 环境配置信息
- `memory/lessons-learned.md` - 经验教训总结
- `memory/project-contexts.md` - 项目上下文

### 2. 技能文件
- 来自 `~/.hermes/skills/` 的自定义技能定义
- 用户创建的专用技能

### 3. 配置文件
- 配置文件模板，不含API密钥等敏感信息
- 部署脚本和设置指南

### 4. 对话上下文
- 重要对话的摘要和关键信息
- 决策记录和问题解决方案

## 使用方法

### 备份当前状态
```bash
# 运行备份脚本
./scripts/backup-hermes.sh
```

### 恢复状态
```bash
# 运行恢复脚本
./scripts/restore-hermes.sh
```

### 设置新环境
```bash
# 首次设置
./scripts/setup-new-machine.sh
```

## 敏感信息处理

**重要**：以下文件包含敏感信息，**不应提交到仓库**：
- `~/.hermes/auth.json` - 认证令牌
- `~/.hermes/.env` - API密钥
- `~/.hermes/config.yaml` - 包含密钥的配置
- 任何包含 `***` 或令牌的文件

## 自动化

### 定期备份
可以通过cron设置定期备份：
```bash
# 每天备份一次
0 0 * * * /home/fjt/hermes-memory-project/scripts/backup-hermes.sh
```

### GitHub Actions
可设置GitHub Actions自动同步：
```yaml
name: Sync Hermes Memory
on:
  push:
    branches: [ main ]
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Sync memory
        run: ./scripts/sync-to-hermes.sh
```

## 注意事项

1. 定期运行备份脚本以保持信息更新
2. 新机器部署时先运行设置脚本
3. 修改配置后记得重新备份
4. 如有敏感信息泄露，立即更改相关凭证