#!/bin/bash

# 腾讯 Edge One Pages 部署脚本
# 使用方法: ./deploy.sh

echo "🚀 开始准备腾讯 Edge One Pages 部署文件..."

# 检查必要文件是否存在
if [ ! -f "functions/_worker.js" ]; then
    echo "❌ 错误: functions/_worker.js 文件不存在"
    exit 1
fi

echo "✅ 找到主要部署文件: functions/_worker.js"

# 检查备选文件
if [ -f "static/index.html" ] && [ -f "functions/proxy.js" ]; then
    echo "✅ 同时找到分离模式文件: static/index.html 和 functions/proxy.js"
    SPLIT_MODE=true
else
    echo "ℹ️  使用单文件 Worker 模式部署"
    SPLIT_MODE=false
fi

# 创建部署包目录
DEPLOY_DIR="deploy-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEPLOY_DIR"

echo "📁 创建部署目录: $DEPLOY_DIR"

# 复制文件到部署目录
cp -r functions "$DEPLOY_DIR/"
cp edge-one.config.json "$DEPLOY_DIR/"
cp README.md "$DEPLOY_DIR/"

if [ "$SPLIT_MODE" = true ]; then
    cp -r static "$DEPLOY_DIR/"
fi

echo "📋 文件清单:"
echo "  ✅ functions/_worker.js - 完整 Worker 文件（推荐）"
if [ "$SPLIT_MODE" = true ]; then
    echo "  ✅ static/index.html - 前端页面（备选）"
    echo "  ✅ functions/proxy.js - Edge Function 代理（备选）"
fi
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
echo "3. 上传 ${DEPLOY_DIR}.zip 或手动上传文件"
echo ""
echo "🎯 推荐部署方式（单文件 Worker 模式）:"
echo "   - 上传 functions/_worker.js 到 Edge Functions 目录"
echo "   - 配置路由: /* -> _worker.js"
echo ""
if [ "$SPLIT_MODE" = true ]; then
    echo "🔄 备选部署方式（分离模式）:"
    echo "   - static/index.html -> 静态文件目录"
    echo "   - functions/proxy.js -> Edge Functions 目录"
    echo "   - 静态路由: / 和 /index.html -> static/index.html"
    echo "   - 函数路由: /* (排除静态文件) -> functions/proxy.js"
    echo ""
fi
echo "4. 部署并测试"
echo ""
echo "📖 详细部署说明请查看 README.md 文件"
echo ""
echo "🔗 测试链接示例:"
echo "   GitHub: https://your-domain.com/https://github.com/user/repo/file"
echo "   Docker: docker pull your-domain.com/nginx:latest"