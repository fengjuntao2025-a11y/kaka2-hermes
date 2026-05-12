# GitHub 设置指南

## 当前状态
✅ 本地Git仓库已创建
✅ 所有文件已提交 (369个文件, 121242行)
✅ 敏感信息已过滤（API密钥、令牌等）

## 需要你完成的步骤

### 1. 创建GitHub仓库
打开浏览器访问: https://github.com/new

**设置选项:**
- Repository name: `hermes-memory` (或你喜欢的名字)
- Description: `Hermes Agent 记忆与上下文备份`
- Private ✅ (推荐，包含个人配置)
- ❌ 不要勾选 "Add a README file"
- ❌ 不要勾选 "Add .gitignore" (我们已经有了)
- ❌ 不要选择 License

点击 "Create repository"

### 2. 获取Personal Access Token (PAT)
打开: https://github.com/settings/tokens

点击 "Generate new token" → "Generate new token (classic)"

**设置选项:**
- Note: `hermes-memory-backup`
- Expiration: `90 days` (或自定义)
- Select scopes:
  - ✅ `repo` (Full control of private repositories)
  - ✅ `workflow` (可选，用于GitHub Actions)

点击 "Generate token"

**⚠️ 重要: 复制生成的token，只会显示一次!**

### 3. 推送到GitHub

将以下命令中的 `YOUR_USERNAME` 和 `YOUR_TOKEN` 替换为你的实际信息:

```bash
# 进入项目目录
cd ~/hermes-memory-project

# 添加远程仓库
git remote add origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/hermes-memory.git

# 推送到GitHub
git push -u origin master
```

例如:
```bash
git remote add origin https://fengjuntao:ghp_xxxxxxxxxxxx@github.com/fengjuntao/hermes-memory.git
git push -u origin master
```

### 4. 验证推送成功
访问你的GitHub仓库页面，应该能看到所有文件。

## 后续使用

### 定期备份
```bash
# 运行备份脚本
cd ~/hermes-memory-project
bash scripts/backup-hermes.sh

# 推送更新
git add .
git commit -m "更新备份 $(date +%Y%m%d)"
git push
```

### 新机器恢复
```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/hermes-memory.git

# 运行设置脚本
cd hermes-memory
bash scripts/setup-new-machine.sh
```

### 自动备份 (可选)
可以设置cron定期备份:
```bash
# 编辑crontab
crontab -e

# 添加以下行 (每天凌晨2点备份)
0 2 * * * cd ~/hermes-memory-project && bash scripts/backup-hermes.sh && git add . && git commit -m "自动备份 $(date +\%Y\%m\%d)" && git push
```

## 安全注意事项

1. **Token安全**: 
   - 不要分享你的token
   - 定期轮换token (每90天)
   - 使用后从shell历史中清除

2. **仓库权限**:
   - 保持仓库为Private
   - 不要fork到个人空间
   - 定期检查仓库的collaborators

3. **敏感信息**:
   - 我们已经过滤了API密钥、令牌等
   - 定期检查是否有意外提交的敏感信息
   - 使用 `git log -p | grep -i "token\|key\|secret"` 检查

## 故障排除

### 推送失败
```bash
# 检查远程仓库
git remote -v

# 重新设置远程仓库
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/hermes-memory.git

# 强制推送 (谨慎使用)
git push -f origin master
```

### Token过期
1. 访问 https://github.com/settings/tokens
2. 删除旧token
3. 生成新token
4. 更新远程仓库URL

### 权限问题
确保你的token有 `repo` 权限，仓库是私有的。

## 文件说明

### 包含的文件
- `memory/` - 用户画像、环境配置
- `skills/` - 技能文件 (369个)
- `config/` - 配置模板
- `scripts/` - 自动化脚本
- `contexts/` - 会话上下文

### 不包含的文件 (安全)
- API密钥、令牌
- 认证文件
- 环境变量敏感值
- 临时文件、日志

## 支持

如有问题，检查:
1. GitHub仓库是否创建成功
2. Token是否有效且有正确权限
3. 网络连接是否正常
4. 磁盘空间是否足够

---

**下一步**: 按照上述步骤创建GitHub仓库并推送。完成后再告诉我，我可以帮你验证。