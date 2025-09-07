# 腾讯 Edge One Pages 部署问题排查指南

## 常见问题及解决方案

### 1. 返回 404 页面而不是代理内容

**问题描述**: 访问 `https://your-domain.com/https://github.com/...` 返回腾讯 Edge One 的 404 页面

**可能原因**:
- Edge Function 没有正确处理路由
- 函数文件上传位置错误
- 路由配置不正确

**解决方案**:
1. **检查文件上传**:
   ```
   确保 functions/_worker.js 文件已正确上传到 Edge Functions 目录
   ```

2. **检查路由配置**:
   ```
   路由规则: /* 
   处理方式: Edge Function
   函数文件: _worker.js
   ```

3. **使用单文件模式**:
   ```
   推荐使用 functions/_worker.js（包含完整功能的单文件）
   而不是分离的 static/index.html + functions/proxy.js
   ```

### 2. Edge Function 执行错误

**问题描述**: 函数执行时报错或超时

**排查步骤**:
1. **检查函数日志**:
   - 在腾讯云控制台查看 Edge One Pages 的函数执行日志
   - 查找具体的错误信息

2. **检查函数格式**:
   ```javascript
   // 确保使用正确的导出格式
   export default {
     async fetch(request, env, ctx) {
       return handleRequest(request);
     }
   };
   ```

3. **检查依赖**:
   - 确保所有使用的 Web API 都被 Edge One 支持
   - 避免使用 Node.js 特有的 API

### 3. CORS 跨域问题

**问题描述**: 浏览器报 CORS 错误

**解决方案**:
```javascript
// 确保响应包含正确的 CORS 头
newResponse.headers.set('Access-Control-Allow-Origin', '*');
newResponse.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS');
```

### 4. GitHub 文件下载失败

**问题描述**: GitHub 文件无法下载或下载缓慢

**排查步骤**:
1. **检查白名单配置**:
   ```javascript
   const ALLOWED_HOSTS = [
     'github.com',
     'api.github.com', 
     'raw.githubusercontent.com',
     'gist.github.com',
     'gist.githubusercontent.com'
   ];
   ```

2. **检查 URL 格式**:
   ```
   正确格式: https://your-domain.com/https://github.com/user/repo/file
   错误格式: https://your-domain.com/github.com/user/repo/file
   ```

3. **测试连接**:
   ```bash
   curl -I "https://your-domain.com/https://github.com/fscarmen2/Cloudflare-Accel/raw/main/README.md"
   ```

### 5. Docker 镜像拉取失败

**问题描述**: Docker 命令执行失败

**排查步骤**:
1. **检查 Docker Registry API**:
   ```bash
   curl "https://your-domain.com/v2/"
   # 应该返回 200 或 401 状态码
   ```

2. **检查镜像格式**:
   ```bash
   # 正确的命令格式
   docker pull your-domain.com/hello-world
   docker pull your-domain.com/library/nginx
   docker pull your-domain.com/ghcr.io/user/repo
   ```

3. **检查认证流程**:
   - 确保 `handleToken` 函数正常工作
   - 检查 Docker Hub 的认证响应

### 6. 性能问题

**问题描述**: 访问速度慢或超时

**优化建议**:
1. **启用缓存**:
   ```javascript
   // 在响应中添加缓存头
   response.headers.set('Cache-Control', 'public, max-age=3600');
   ```

2. **检查节点分布**:
   - 确认腾讯 Edge One 在目标地区有节点
   - 检查 DNS 解析是否指向最近的节点

3. **监控指标**:
   - 查看腾讯云控制台的性能监控
   - 关注响应时间和错误率

## 调试工具

### 1. 使用测试脚本
```bash
./test-deployment.sh your-domain.com
```

### 2. 手动测试命令
```bash
# 测试首页
curl -I "https://your-domain.com/"

# 测试 GitHub 代理
curl -I "https://your-domain.com/https://github.com/fscarmen2/Cloudflare-Accel/raw/main/README.md"

# 测试 Docker API
curl -I "https://your-domain.com/v2/"

# 测试具体镜像
curl -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
     "https://your-domain.com/v2/library/hello-world/manifests/latest"
```

### 3. 浏览器开发者工具
- 打开 Network 面板查看请求详情
- 检查 Console 面板的错误信息
- 查看 Response Headers 确认 CORS 设置

## 配置检查清单

### 部署前检查
- [ ] `functions/_worker.js` 文件存在且完整
- [ ] 白名单配置正确
- [ ] 导出格式符合 Edge One 要求

### 部署后检查
- [ ] 文件上传成功
- [ ] 路由配置正确 (`/*` -> `_worker.js`)
- [ ] 域名解析正常
- [ ] SSL 证书有效

### 功能测试
- [ ] 首页可以正常访问
- [ ] GitHub 文件可以下载
- [ ] Docker 镜像可以拉取
- [ ] CORS 头设置正确

## 联系支持

如果问题仍然存在，请收集以下信息：

1. **错误信息**: 完整的错误日志
2. **测试命令**: 失败的具体命令
3. **配置信息**: 路由配置截图
4. **环境信息**: 域名、部署时间等

然后可以：
- 查看腾讯云 Edge One 官方文档
- 提交工单到腾讯云技术支持
- 在项目 GitHub 仓库提交 Issue

## 最佳实践

1. **使用单文件模式**: 推荐使用 `_worker.js` 而不是分离模式
2. **定期测试**: 使用提供的测试脚本定期检查服务状态
3. **监控告警**: 设置腾讯云监控告警，及时发现问题
4. **备份配置**: 保存好配置文件，便于快速恢复
5. **版本管理**: 使用 Git 管理代码变更