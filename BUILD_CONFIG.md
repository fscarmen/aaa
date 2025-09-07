# 腾讯 Edge One Pages 构建部署配置指南

## 🔧 构建配置设置

### 1. 基础配置

在腾讯 Edge One Pages 控制台创建项目时，请按以下配置：

#### 项目基本信息
- **项目名称**: `github-docker-accel`
- **描述**: `GitHub 和 Docker 资源加速代理服务`
- **框架**: `其他` 或 `静态网站`

#### 构建设置
```yaml
构建命令: (留空)
输出目录: static
安装命令: (留空)
根目录: /
Node.js 版本: 18.x
```

### 2. 文件结构配置

#### 推荐结构（单文件模式）
```
项目根目录/
├── functions/
│   └── _worker.js          # 主要 Edge Function
└── static/                 # 静态文件目录（可选）
    └── index.html         # 备用静态页面
```

#### 备选结构（分离模式）
```
项目根目录/
├── functions/
│   └── proxy.js           # Edge Function 代理逻辑
└── static/
    └── index.html         # 前端页面
```

### 3. 路由配置

#### 方案一：单文件模式（推荐）
```json
{
  "routes": [
    {
      "pattern": "/*",
      "function": "functions/_worker.js",
      "method": ["GET", "POST", "HEAD", "OPTIONS"]
    }
  ]
}
```

#### 方案二：分离模式
```json
{
  "routes": [
    {
      "pattern": "/",
      "static": "static/index.html"
    },
    {
      "pattern": "/index.html", 
      "static": "static/index.html"
    },
    {
      "pattern": "/*",
      "function": "functions/proxy.js",
      "method": ["GET", "POST", "HEAD", "OPTIONS"]
    }
  ]
}
```

### 4. 环境变量配置

在 Edge One Pages 控制台的环境变量设置：

```bash
NODE_ENV=production
```

### 5. 域名配置

#### 自定义域名设置
1. 在 Edge One Pages 项目设置中添加自定义域名
2. 配置 DNS 记录指向 Edge One 提供的 CNAME
3. 等待 SSL 证书自动配置完成

#### DNS 配置示例
```
类型: CNAME
名称: your-subdomain (或 @)
值: your-project.edge-one-pages.com
TTL: 自动
```

## 📋 部署步骤详解

### 步骤 1: 准备项目文件

```bash
# 1. 进入项目目录
cd eo-accel/edge-one

# 2. 运行部署脚本
./deploy.sh

# 3. 检查生成的部署包
ls -la deploy-*.zip
```

### 步骤 2: 创建 Edge One Pages 项目

1. **登录腾讯云控制台**
   - 访问: https://console.cloud.tencent.com/
   - 进入 Edge One → Pages

2. **创建新项目**
   - 点击"创建项目"
   - 选择"上传代码包"或"Git 仓库"

3. **配置项目设置**
   ```
   项目名称: github-docker-accel
   框架: 其他
   构建命令: (留空)
   输出目录: static
   ```

### 步骤 3: 上传文件

#### 方法一: 上传代码包
1. 选择生成的 `deploy-YYYYMMDD-HHMMSS.zip` 文件
2. 上传并等待解压完成

#### 方法二: 手动上传文件
1. **上传 Edge Function**:
   - 文件: `functions/_worker.js`
   - 位置: Functions 目录

2. **上传静态文件**（可选）:
   - 文件: `static/index.html`
   - 位置: Static 目录

### 步骤 4: 配置路由规则

在项目设置 → 路由配置中添加：

#### 单文件模式路由
```
路径模式: /*
处理方式: Edge Function
函数文件: _worker.js
HTTP 方法: GET, POST, HEAD, OPTIONS
```

#### 分离模式路由
```
# 静态文件路由
路径模式: /
处理方式: 静态文件
文件: static/index.html

路径模式: /index.html
处理方式: 静态文件  
文件: static/index.html

# 代理路由
路径模式: /*
处理方式: Edge Function
函数文件: proxy.js
排除路径: /, /index.html, /static/*
```

### 步骤 5: 部署和测试

1. **触发部署**
   - 保存配置后自动触发部署
   - 等待部署完成（通常 1-3 分钟）

2. **测试部署**
   ```bash
   # 使用提供的测试脚本
   ./test-deployment.sh your-domain.com
   
   # 或手动测试
   curl https://your-domain.com/
   curl https://your-domain.com/https://github.com/fscarmen2/Cloudflare-Accel/raw/main/README.md
   ```

## 🔍 配置验证清单

### 部署前检查
- [ ] `functions/_worker.js` 文件完整且语法正确
- [ ] 白名单配置符合需求
- [ ] 文件结构符合要求

### 部署配置检查
- [ ] 项目名称和描述正确
- [ ] 构建命令配置正确（通常为空）
- [ ] 输出目录设置为 `static`
- [ ] 路由规则配置正确

### 部署后验证
- [ ] 项目部署状态为"成功"
- [ ] 自定义域名解析正常
- [ ] SSL 证书配置完成
- [ ] 所有测试用例通过

## 🚨 常见配置问题

### 1. 路由配置错误
**问题**: 访问返回 404
**解决**: 确保路由模式为 `/*` 且指向正确的函数文件

### 2. 函数执行失败
**问题**: 500 错误或函数超时
**解决**: 检查函数代码语法，确保导出格式正确

### 3. 静态文件无法访问
**问题**: 静态资源 404
**解决**: 确认文件上传到 `static` 目录且路由配置正确

### 4. 域名解析问题
**问题**: 自定义域名无法访问
**解决**: 检查 DNS 配置，确保 CNAME 记录正确

## 📊 性能优化配置

### 缓存设置
```json
{
  "headers": [
    {
      "source": "/static/*",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=86400"
        }
      ]
    },
    {
      "source": "/*",
      "headers": [
        {
          "key": "Cache-Control", 
          "value": "public, max-age=3600"
        }
      ]
    }
  ]
}
```

### 安全头设置
```json
{
  "headers": [
    {
      "source": "/*",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection", 
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
```

## 📞 技术支持

如果在配置过程中遇到问题：

1. **查看官方文档**: [腾讯云 Edge One Pages 文档](https://cloud.tencent.com/document/product/1552)
2. **检查部署日志**: 在控制台查看详细的部署和运行日志
3. **使用测试工具**: 运行 `./test-deployment.sh` 进行诊断
4. **参考排查指南**: 查看 `TROUBLESHOOTING.md` 文件

配置完成后，你的 GitHub 和 Docker 加速服务就可以正常运行了！🎉