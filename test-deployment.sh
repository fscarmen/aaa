#!/bin/bash

# 腾讯 Edge One Pages 部署测试脚本
# 使用方法: ./test-deployment.sh your-domain.com

if [ $# -eq 0 ]; then
    echo "❌ 请提供域名参数"
    echo "使用方法: ./test-deployment.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
echo "🧪 开始测试腾讯 Edge One Pages 部署: $DOMAIN"
echo ""

# 测试首页
echo "1️⃣ 测试首页访问..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 首页访问正常 (HTTP $HTTP_CODE)"
else
    echo "❌ 首页访问失败 (HTTP $HTTP_CODE)"
fi

# 测试 GitHub 代理
echo ""
echo "2️⃣ 测试 GitHub 文件代理..."
TEST_GITHUB_URL="https://$DOMAIN/https://github.com/fscarmen2/Cloudflare-Accel/raw/main/README.md"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_GITHUB_URL")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ GitHub 代理正常 (HTTP $HTTP_CODE)"
    echo "   测试链接: $TEST_GITHUB_URL"
else
    echo "❌ GitHub 代理失败 (HTTP $HTTP_CODE)"
    echo "   测试链接: $TEST_GITHUB_URL"
fi

# 测试 Docker 代理
echo ""
echo "3️⃣ 测试 Docker 镜像代理..."
TEST_DOCKER_URL="https://$DOMAIN/v2/"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_DOCKER_URL")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "✅ Docker 代理正常 (HTTP $HTTP_CODE)"
    echo "   测试链接: $TEST_DOCKER_URL"
else
    echo "❌ Docker 代理失败 (HTTP $HTTP_CODE)"
    echo "   测试链接: $TEST_DOCKER_URL"
fi

# 测试具体 Docker 镜像
echo ""
echo "4️⃣ 测试具体 Docker 镜像..."
TEST_DOCKER_MANIFEST="https://$DOMAIN/v2/library/hello-world/manifests/latest"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Accept: application/vnd.docker.distribution.manifest.v2+json" "$TEST_DOCKER_MANIFEST")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "✅ Docker 镜像代理正常 (HTTP $HTTP_CODE)"
    echo "   测试链接: $TEST_DOCKER_MANIFEST"
else
    echo "❌ Docker 镜像代理失败 (HTTP $HTTP_CODE)"
    echo "   测试链接: $TEST_DOCKER_MANIFEST"
fi

echo ""
echo "🎯 测试完成！"
echo ""
echo "📝 使用示例:"
echo "GitHub 加速: curl https://$DOMAIN/https://github.com/user/repo/file"
echo "Docker 拉取: docker pull $DOMAIN/hello-world"
echo "Docker 拉取: docker pull $DOMAIN/nginx:latest"
echo ""
echo "🌐 访问管理界面: https://$DOMAIN/"