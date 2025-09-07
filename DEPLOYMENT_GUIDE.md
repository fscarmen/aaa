# 腾讯 Edge One Pages 快速部署指南

## 🚀 一键部署步骤

### 1. 准备文件
```bash
# 克隆或下载项目文件
cd eo-accel/edge-one

# 运行部署脚本
./deploy.sh
```

### 2. 上传到腾讯云
1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/)
2. 进入 **Edge One** → **Pages**
3. 点击 **创建项目**
4. 选择 **上传文件** 方式
5. 上传生成的 `deploy-YYYYMMDD-HHMMSS.zip` 文件

### 3. 配置路由（重要）
在 Edge One Pages 控制台配置：
- **路由规则**: `/*`
- **处理方式**: Edge Function  
- **函数文件**: `functions/_worker.js`

### 4. 测试部署
```bash
# 使用测试脚本验证
./test-deployment.sh your-domain.com
```

## 📁 项目文件说明

```
eo-accel/edge-one/
├── functions/
│   ├── _worker.js          # 🎯 主要部署文件（推荐）
│   └── proxy.js           # 备选：分离模式的代理逻辑
├── static/
│   └── index.html         # 备选：分离模式的前端页面
├── deploy.sh              # 🔧 自动部署脚本
├── test-deployment.sh     # 🧪 部署测试脚本
├── README.md              # 📖 详细文档
├── TROUBLESHOOTING.md     # 🔍 问题排查指南
└── DEPLOYMENT_GUIDE.md    # 📋 本文件
```

## ⚡ 核心功能

### GitHub 文件加速
```bash
# 原始链接
https://github.com/user/repo/releases/download/v1.0.0/file.zip

# 加速链接
https://your-domain.com/https://github.com/user/repo/releases/download/v1.0.0/file.zip
```

### Docker 镜像加速
```bash
# 官方镜像
docker pull your-domain.com/nginx:latest
docker pull your-domain.com/hello-world

# 第三方镜像  
docker pull your-domain.com/ghcr.io/user/repo:tag
docker pull your-domain.com/quay.io/user/repo:tag
```

## 🎯 关键配置

### 白名单域名
```javascript
const ALLOWED_HOSTS = [
  'github.com',
  'api.github.com', 
  'raw.githubusercontent.com',
  'gist.github.com',
  'gist.githubusercontent.com',
  'quay.io',
  'gcr.io',
  'k8s.gcr.io', 
  'registry.k8s.io',
  'ghcr.io',
  'docker.cloudsmith.io',
  'registry-1.docker.io'
];
```

### 路径限制（可选）
```javascript
const RESTRICT_PATHS = false;  // 设为 true 启用路径限制
const ALLOWED_PATHS = ['library', 'user-id-1', 'user-id-2'];
```

## 🔧 常用命令

### 部署相关
```bash
# 准备部署文件
./deploy.sh

# 测试部署结果
./test-deployment.sh your-domain.com
```

### 测试命令
```bash
# 测试首页
curl https://your-domain.com/

# 测试 GitHub 代理
curl https://your-domain.com/https://github.com/fscarmen2/Cloudflare-Accel/raw/main/README.md

# 测试 Docker API
curl https://your-domain.com/v2/

# 测试 Docker 镜像
docker pull your-domain.com/hello-world
```

## 🚨 注意事项

### 1. 文件选择
- **推荐**: 使用 `functions/_worker.js`（单文件，包含完整功能）
- **备选**: 使用 `static/index.html` + `functions/proxy.js`（分离模式）

### 2. 路由配置
- 单文件模式：`/*` → `_worker.js`
- 分离模式：需要配置静态文件路由和函数路由

### 3. 域名要求
- 建议使用已备案的域名（大陆访问更稳定）
- 确保域名已正确接入腾讯 Edge One

### 4. 性能优化
- 利用腾讯云全球节点加速
- 自动处理缓存和 CDN 分发
- 支持 HTTP/2 和 HTTP/3

## 🔍 问题排查

### 返回 404 页面
1. 检查 `_worker.js` 文件是否正确上传
2. 确认路由配置：`/*` → `_worker.js`
3. 查看函数执行日志

### GitHub 下载失败
1. 检查 URL 格式是否正确
2. 确认目标域名在白名单中
3. 测试网络连接

### Docker 拉取失败
1. 检查 Docker Registry API：`curl https://your-domain.com/v2/`
2. 确认镜像名称格式正确
3. 检查认证流程

详细排查步骤请参考 `TROUBLESHOOTING.md`

## 📞 技术支持

- **项目文档**: `README.md`
- **问题排查**: `TROUBLESHOOTING.md`  
- **原始项目**: [fscarmen2/Cloudflare-Accel](https://github.com/fscarmen2/Cloudflare-Accel)
- **腾讯云文档**: [Edge One Pages 官方文档](https://cloud.tencent.com/document/product/1552)

## 🎉 部署成功标志

部署成功后，你应该能够：
- ✅ 访问 `https://your-domain.com/` 看到管理界面
- ✅ 使用 GitHub 文件加速下载
- ✅ 使用 Docker 镜像加速拉取
- ✅ 通过测试脚本验证所有功能正常

恭喜！你已经成功部署了腾讯 Edge One 版本的 GitHub 和 Docker 加速服务！🎊