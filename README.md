# EdgeOne 加速服务

这是一个适用于腾讯 EdgeOne Pages 的加速服务，支持 GitHub 文件和 Docker 镜像加速。

## 功能特点

1. GitHub 文件加速
2. Docker 镜像加速（支持多个镜像仓库）
3. 自动处理 Docker 认证
4. 自动处理 AWS S3 重定向
5. 响应式设计，支持暗黑模式

## 目录结构

```
.
├── static/
│   └── index.html      # 主页
├── functions/
│   └── proxy.js        # 边缘函数
├── eop.config.js       # EdgeOne Pages 配置
└── package.json        # 项目配置
```

## 部署到 EdgeOne Pages

1. 登录 [腾讯 EdgeOne 控制台](https://console.cloud.tencent.com/edgeone)
2. 进入 Pages 服务
3. 创建新项目或选择现有项目
4. 连接你的 Git 仓库（GitHub、GitLab 等）
5. 配置构建设置：
   - 构建命令: `npm run build` (如果需要)
   - 发布目录: `./`
6. 点击部署

## 使用方法

### GitHub 文件加速

1. 在输入框中输入 GitHub 文件链接，例如：
   ```
   https://github.com/user/repo/releases/download/v1.0.0/file.zip
   ```

2. 点击"获取加速链接"按钮
3. 复制生成的加速链接或直接打开

### Docker 镜像加速

1. 在输入框中输入镜像地址，例如：
   ```
   hello-world
   ghcr.io/user/repo
   ```

2. 点击"获取加速命令"按钮
3. 复制生成的 docker pull 命令并执行

## 支持的镜像仓库

- Docker Hub (registry-1.docker.io)
- GitHub Container Registry (ghcr.io)
- Google Container Registry (gcr.io)
- Kubernetes Container Registry (k8s.gcr.io, registry.k8s.io)
- Quay (quay.io)
- Cloudsmith (docker.cloudsmith.io)

## 自定义配置

你可以在 [functions/proxy.js](functions/proxy.js) 文件中修改以下配置：

- `ALLOWED_HOSTS`: 允许代理的域名列表
- `RESTRICT_PATHS`: 是否限制路径访问
- `ALLOWED_PATHS`: 允许的路径关键字列表

## 许可证

MIT