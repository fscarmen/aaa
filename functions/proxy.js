// 腾讯 Edge One Pages 代理函数 - 基于原始 Cloudflare Worker 功能
export default async function(request, env) {
    const url = new URL(request.url);
    let path = url.pathname;

    // 处理 CORS 预检请求
    if (request.method === 'OPTIONS') {
        return new Response(null, {
            status: 200,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Max-Age': '86400',
            }
        });
    }

    // 配置白名单
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

    // 处理 Docker V2 API 或 GitHub 代理请求
    let isV2Request = false;
    let v2RequestType = null;
    let v2RequestTag = null;
    
    if (path.startsWith('/v2/')) {
        isV2Request = true;
        path = path.replace('/v2/', '');
        
        const pathSegments = path.split('/').filter(part => part);
        if (pathSegments.length >= 3) {
            v2RequestType = pathSegments[pathSegments.length - 2];
            v2RequestTag = pathSegments[pathSegments.length - 1];
            path = pathSegments.slice(0, pathSegments.length - 2).join('/');
        }
    }

    // 提取目标域名和路径
    const pathParts = path.split('/').filter(part => part);
    if (pathParts.length < 1) {
        return new Response('Invalid request: target domain or path required\n', { status: 400 });
    }

    let targetDomain, targetPath, isDockerRequest = false;
    const fullPath = path.startsWith('/') ? path.substring(1) : path;

    if (fullPath.startsWith('https://') || fullPath.startsWith('http://')) {
        // 处理完整 URL 格式
        const urlObj = new URL(fullPath);
        targetDomain = urlObj.hostname;
        targetPath = urlObj.pathname.substring(1) + urlObj.search;
        isDockerRequest = ['quay.io', 'gcr.io', 'k8s.gcr.io', 'registry.k8s.io', 'ghcr.io', 'docker.cloudsmith.io', 'registry-1.docker.io', 'docker.io'].includes(targetDomain);
        
        if (targetDomain === 'docker.io') {
            targetDomain = 'registry-1.docker.io';
        }
    } else {
        // 处理 Docker 镜像路径
        if (pathParts[0] === 'docker.io') {
            isDockerRequest = true;
            targetDomain = 'registry-1.docker.io';
            if (pathParts.length === 2) {
                targetPath = `library/${pathParts[1]}`;
            } else {
                targetPath = pathParts.slice(1).join('/');
            }
        } else if (ALLOWED_HOSTS.includes(pathParts[0])) {
            targetDomain = pathParts[0];
            targetPath = pathParts.slice(1).join('/') + url.search;
            isDockerRequest = ['quay.io', 'gcr.io', 'k8s.gcr.io', 'registry.k8s.io', 'ghcr.io', 'docker.cloudsmith.io', 'registry-1.docker.io'].includes(targetDomain);
        } else if (pathParts[0] === 'library') {
            isDockerRequest = true;
            targetDomain = 'registry-1.docker.io';
            targetPath = pathParts.join('/');
        } else if (pathParts.length >= 2) {
            isDockerRequest = true;
            targetDomain = 'registry-1.docker.io';
            targetPath = pathParts.join('/');
        } else {
            isDockerRequest = true;
            targetDomain = 'registry-1.docker.io';
            targetPath = `library/${pathParts.join('/')}`;
        }
    }

    // 白名单检查
    if (!ALLOWED_HOSTS.includes(targetDomain)) {
        return new Response(`Error: Invalid target domain.\n`, { status: 400 });
    }

    // 构建目标 URL
    let targetUrl;
    if (isDockerRequest) {
        if (isV2Request && v2RequestType && v2RequestTag) {
            targetUrl = `https://${targetDomain}/v2/${targetPath}/${v2RequestType}/${v2RequestTag}`;
        } else {
            targetUrl = `https://${targetDomain}/${isV2Request ? 'v2/' : ''}${targetPath}`;
        }
    } else {
        targetUrl = `https://${targetDomain}/${targetPath}`;
    }

    // 处理 Docker 认证
    async function handleToken(realm, service, scope) {
        const tokenUrl = `${realm}?service=${service}&scope=${scope}`;
        try {
            const tokenResponse = await fetch(tokenUrl, {
                method: 'GET',
                headers: { 'Accept': 'application/json' }
            });
            if (!tokenResponse.ok) return null;
            const tokenData = await tokenResponse.json();
            return tokenData.token || tokenData.access_token;
        } catch (error) {
            return null;
        }
    }

    // 检查是否为 AWS S3
    function isAmazonS3(url) {
        try {
            return new URL(url).hostname.includes('amazonaws.com');
        } catch {
            return false;
        }
    }

    function getEmptyBodySHA256() {
        return 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    }

    try {
        const newRequestHeaders = new Headers(request.headers);
        newRequestHeaders.set('Host', targetDomain);
        newRequestHeaders.delete('x-amz-content-sha256');
        newRequestHeaders.delete('x-amz-date');
        newRequestHeaders.delete('x-amz-security-token');
        newRequestHeaders.delete('x-amz-user-agent');

        if (isAmazonS3(targetUrl)) {
            newRequestHeaders.set('x-amz-content-sha256', getEmptyBodySHA256());
            newRequestHeaders.set('x-amz-date', new Date().toISOString().replace(/[-:T]/g, '').slice(0, -5) + 'Z');
        }

        let response = await fetch(targetUrl, {
            method: request.method,
            headers: newRequestHeaders,
            body: request.body,
            redirect: 'manual'
        });

        // 处理 Docker 认证挑战
        if (isDockerRequest && response.status === 401) {
            const wwwAuth = response.headers.get('WWW-Authenticate');
            if (wwwAuth) {
                const authMatch = wwwAuth.match(/Bearer realm="([^"]+)",service="([^"]*)",scope="([^"]*)"/);
                if (authMatch) {
                    const [, realm, service, scope] = authMatch;
                    const token = await handleToken(realm, service || targetDomain, scope);
                    
                    if (token) {
                        const authHeaders = new Headers(request.headers);
                        authHeaders.set('Authorization', `Bearer ${token}`);
                        authHeaders.set('Host', targetDomain);
                        
                        if (isAmazonS3(targetUrl)) {
                            authHeaders.set('x-amz-content-sha256', getEmptyBodySHA256());
                            authHeaders.set('x-amz-date', new Date().toISOString().replace(/[-:T]/g, '').slice(0, -5) + 'Z');
                        } else {
                            authHeaders.delete('x-amz-content-sha256');
                            authHeaders.delete('x-amz-date');
                            authHeaders.delete('x-amz-security-token');
                            authHeaders.delete('x-amz-user-agent');
                        }

                        response = await fetch(targetUrl, {
                            method: request.method,
                            headers: authHeaders,
                            body: request.body,
                            redirect: 'manual'
                        });
                    }
                }
            }
        }

        // 处理重定向
        if (isDockerRequest && (response.status === 307 || response.status === 302)) {
            const redirectUrl = response.headers.get('Location');
            if (redirectUrl) {
                const redirectHeaders = new Headers(request.headers);
                redirectHeaders.set('Host', new URL(redirectUrl).hostname);
                
                if (isAmazonS3(redirectUrl)) {
                    redirectHeaders.set('x-amz-content-sha256', getEmptyBodySHA256());
                    redirectHeaders.set('x-amz-date', new Date().toISOString().replace(/[-:T]/g, '').slice(0, -5) + 'Z');
                }
                
                if (response.headers.get('Authorization')) {
                    redirectHeaders.set('Authorization', response.headers.get('Authorization'));
                }

                response = await fetch(redirectUrl, {
                    method: request.method,
                    headers: redirectHeaders,
                    body: request.body,
                    redirect: 'manual'
                });
            }
        }

        // 构建响应
        const newResponse = new Response(response.body, response);
        newResponse.headers.set('Access-Control-Allow-Origin', '*');
        newResponse.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS');
        
        if (isDockerRequest) {
            newResponse.headers.set('Docker-Distribution-API-Version', 'registry/2.0');
            newResponse.headers.delete('Location');
        }
        
        return newResponse;

    } catch (error) {
        return new Response(`Error fetching from ${targetDomain}: ${error.message}\n`, { status: 500 });
    }
}