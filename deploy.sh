#!/bin/bash

# 腾讯 Edge One Pages 部署脚本
# 使用方法: ./deploy.sh

echo "🚀 开始准备腾讯 Edge One Pages 部署文件..."

# 检查必要文件是否存在
if [ ! -f "static/index.html" ]; then
    echo "❌ 错误: static/index.html 文件不存在"
    exit 1
fi

if [ ! -f "functions/proxy.js" ]; then
    echo "❌ 错误: functions/proxy.js 文件不存在"
    exit 1
fi

# 创建部署包目录
DEPLOY_DIR="deploy-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEPLOY_DIR"

echo "📁 创建部署目录: $DEPLOY_DIR"

# 复制文件到部署目录
cp -r static "$DEPLOY_DIR/"
cp -r functions "$DEPLOY_DIR/"
cp edge-one.config.json "$DEPLOY_DIR/"
cp README.md "$DEPLOY_DIR/"

echo "📋 文件清单:"
echo "  ✅ static/index.html - 前端页面"
echo "  ✅ functions/proxy.js - Edge Function 代理"
echo "  ✅ edge-one.config.json - 配置文件"
echo "  ✅ README.md - 部署说明"

# 创建压缩包
if command -v zip &> /dev/null; then
    cd "$DEPLOY_DIR"
    zip -r "../${DEPLOY_DIR}.zip" .
    cd ..
    echo "📦 已创建部署压缩包: ${DEPLOY_DIR}.zip"
fi

echo ""
echo "🎉 部署文件准备完成!"
echo ""
echo "📝 下一步操作:"
echo "1. 登录腾讯云控制台 -> Edge One -> Pages"
echo "2. 创建新项目，选择'上传文件'方式"
echo "3. 上传 ${DEPLOY_DIR}.zip 或手动上传以下文件:"
echo "   - static/index.html -> 静态文件目录"
echo "   - functions/proxy.js -> Edge Functions 目录"
echo "4. 配置路由规则:"
echo "   - 静态路由: / 和 /index.html -> static/index.html"
echo "   - 函数路由: /* (排除 /index.html) -> functions/proxy.js"
echo "5. 部署并测试"
echo ""
echo "📖 详细部署说明请查看 README.md 文件"
echo ""
echo "🔗 测试链接示例:"
echo "   GitHub: https://your-domain.com/https://github.com/user/repo/file"
echo "   Docker: docker pull your-domain.com/nginx:latest"