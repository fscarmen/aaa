# 腾讯 Edge One Pages 部署指南

## 项目简介

这是一个基于腾讯 Edge One Pages 的 GitHub 和 Docker 资源加速代理服务，帮助大陆用户快速访问 GitHub 文件和 Docker 镜像。

## 功能特性

- ✅ GitHub 文件加速下载
- ✅ Docker 镜像加速拉取
- ✅ 支持多种 Docker 镜像仓库（Docker Hub、ghcr.io、quay.io 等）
- ✅ 自动处理 Docker 认证和重定向
- ✅ 支持 AWS S3 签名
- ✅ 响应式 Web 界面
- ✅ 暗黑模式支持
- ✅ 全程反向代理，避免客户端直连被墙服务

## 文件结构

```
eo-accel/edge-one/
├── static/
│   └── index.html          # 前端页面
├── functions/
│   └── proxy.js           # Edge Function 代理逻辑
├── edge-one.config.json   # Edge One 配置文件
└── README.md             # 部署说明
```

## 部署步骤

### 1. 准备工作

1. 注册腾讯云账号并开通 Edge One 服务
2. 准备一个域名并完成备案（如需要）
3. 将域名接入腾讯 Edge One

### 2. 创建 Pages 项目

1. 登录腾讯云控制台，进入 Edge One 服务
2. 选择"Pages"功能
3. 点击"创建项目"
4. 选择"上传文件"方式

### 3. 上传项目文件

将以下文件上传到对应目录：

```
static/index.html    -> 上传到静态文件目录
functions/proxy.js   -> 上传到 Edge Functions 目录
```

### 4. 配置路由规则

在 Edge One Pages 控制台配置以下路由规则：

#### 静态文件路由
- 路径：`/` 和 `/index.html`
- 处理方式：静态文件服务
- 文件：`static/index.html`

#### Edge Function 路由
- 路径：`/*`（除静态文件外的所有路径）
- 处理方式：Edge Function
- 函数：`proxy.js`
- 排除路径：`/index.html`, `/static/*`

### 5. 环境变量配置（可选）

如需自定义配置，可在 `functions/proxy.js` 中修改以下变量：

```javascript
// 允许的域名白名单
const ALLOWED_HOSTS = [
  'quay.io',
  'gcr.io',
  'k8s.gcr.io',
  'registry.k8s.io',
  'ghcr.io',
  'docker.cloudsmith.io',
  'registry-1.docker.io',
  'github.com',
  'api.github.com',
  'raw.githubusercontent.com',
  'gist.github.com',
  'gist.githubusercontent.com'
];

// 是否启用路径限制
const RESTRICT_PATHS = false;

// 允许的路径关键字（当 RESTRICT_PATHS = true 时生效）
const ALLOWED_PATHS = [
  'library',
  'user-id-1',
  'user-id-2',
];
```

### 6. 部署验证

部署完成后，访问你的域名：

1. **首页测试**：访问 `https://your-domain.com` 应该显示加速服务页面
2. **GitHub 加速测试**：
   ```
   https://your-domain.com/https://github.com/user/repo/releases/download/v1.0.0/file.zip
   ```
3. **Docker 加速测试**：
   ```bash
   docker pull your-domain.com/hello-world
   docker pull your-domain.com/nginx:latest
   docker pull your-domain.com/ghcr.io/user/repo:tag
   ```

## 使用方法

### GitHub 文件加速

#### 方法一：通过网页界面
1. 访问部署的网站
2. 在"GitHub 文件加速"区域输入原始 GitHub 链接
3. 点击"获取加速链接"
4. 复制生成的加速链接使用

#### 方法二：直接构造链接
将原始链接前缀替换：
```
原始链接：https://github.com/user/repo/releases/download/v1.0.0/file.zip
加速链接：https://your-domain.com/https://github.com/user/repo/releases/download/v1.0.0/file.zip
```

### Docker 镜像加速

#### 方法一：通过网页界面
1. 访问部署的网站
2. 在"Docker 镜像加速"区域输入镜像名称
3. 点击"获取加速命令"
4. 复制生成的 docker pull 命令执行

#### 方法二：直接使用命令
```bash
# 官方镜像
docker pull your-domain.com/nginx:latest
docker pull your-domain.com/hello-world

# 第三方镜像
docker pull your-domain.com/ghcr.io/user/repo:tag
docker pull your-domain.com/quay.io/user/repo:tag

# 完整格式
docker pull your-domain.com/registry-1.docker.io/library/nginx:latest
```

## 支持的镜像仓库

- Docker Hub (`docker.io` / `registry-1.docker.io`)
- GitHub Container Registry (`ghcr.io`)
- Google Container Registry (`gcr.io`)
- Kubernetes Registry (`k8s.gcr.io`, `registry.k8s.io`)
- Red Hat Quay (`quay.io`)
- Cloudsmith Docker Registry (`docker.cloudsmith.io`)

## 技术特性

### 安全特性
- 域名白名单机制，只允许访问预设的安全域名
- 可选的路径白名单，进一步限制访问范围
- 自动处理 CORS 跨域请求
- 防止恶意重定向攻击

### 性能优化
- 利用腾讯 Edge One 全球节点加速
- 智能缓存策略
- 自动处理 Docker 认证流程
- 支持 HTTP/2 和 HTTP/3

### 兼容性
- 完全兼容 Docker CLI
- 支持所有主流浏览器
- 响应式设计，支持移动设备
- 支持暗黑模式

## 故障排除

### 常见问题

1. **404 错误**
   - 检查路由配置是否正确
   - 确认 Edge Function 已正确部署

2. **403 错误**
   - 检查目标域名是否在白名单中
   - 如启用路径限制，检查路径是否被允许

3. **Docker 认证失败**
   - 检查网络连接
   - 确认镜像名称格式正确

4. **GitHub 下载慢**
   - 检查 Edge One 节点分布
   - 确认域名解析正确

### 日志查看

在腾讯云 Edge One 控制台的"监控"页面可以查看：
- 请求日志
- 错误日志
- 性能指标

## 更新维护

### 更新代码
1. 修改本地文件
2. 重新上传到 Edge One Pages
3. 等待部署完成（通常 1-2 分钟）

### 监控建议
- 定期检查服务可用性
- 监控流量使用情况
- 关注腾讯云账单

## 许可证

本项目基于原始 [fscarmen2/Cloudflare-Accel](https://github.com/fscarmen2/Cloudflare-Accel) 项目改造，遵循相同的开源许可证。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 免责声明

本服务仅用于学习和研究目的，请遵守相关法律法规和服务条款。使用本服务产生的任何问题由使用者自行承担。