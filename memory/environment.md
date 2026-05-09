# 环境配置信息

## 系统环境
- **操作系统**: Linux (Ubuntu/Debian)
- **Python**: 3.x
- **Node.js**: v22.22.1 (via nvm)
- **包管理**: pip, npm, yarn

## 硬件配置
- **GPU**: NVIDIA GeForce RTX 4060 (8GB VRAM)
- **CUDA**: 13.0, driver 580.126.09
- **内存**: 足够用于本地开发
- **存储**: 321GB 总容量，99% 已使用 (5.7GB 可用)

## 网络配置
- **代理**: http_proxy=127.0.0.1:7890
- **内部网络**: 10.x.x.x 网段可直接访问
- **GitHub代理**: http://127.0.0.1:7890 (已配置)

## 已安装工具
- **~/soft/ 目录下的工具**:
  - lingbot-map (14GB)
  - LabelStudio (11GB) 
  - yolov8 (7GB)
  - nebulagraph (6.4GB)

- **Python包**:
  - pytest, xdist (测试框架)
  - VGGT, DINOv2, FlashInfer (ML工具)
  - Viser (可视化工具)

## Hermes配置
- **模型**: mimo-v2-pro (小米)
- **提供者**: xiaomi
- **基础URL**: https://token-plan-cn.xiaomimimo.com/anthropic
- **工具集**: hermes-cli
- **最大轮次**: 90
- **网关超时**: 1800秒

## 飞书集成
- **应用ID**: cli_a9633b4ae5f89cd3
- **连接模式**: websocket
- **域名**: feishu
- **允许所有用户**: true

## 开发环境
- **前端**: React + TypeScript + Vite
- **UI库**: Ant Design 6.3.0
- **后端**: FastAPI/Flask (Python)
- **数据库**: NebulaGraph (图数据库), PostgreSQL, Redis
- **部署**: Docker, Kubernetes

## 文件路径
- **Hermes配置**: ~/.hermes/config.yaml
- **项目目录**: ~/soft/
- **架构文档**: ~/文档/架构/
- **Rail AIOS**: ~/文档/架构/Rail_AIOS/
- **LingBot-Map**: ~/soft/lingbot-map/lingbot-map/

## 注意事项
1. **磁盘空间**: 仅剩5.7GB，需要定期清理
2. **代理问题**: 内网访问需要 --noproxy '*' 或取消代理设置
3. **包管理**: 使用npm/yarn时注意代理配置
4. **GitHub**: 已配置代理，可正常访问