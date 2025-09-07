// 腾讯 Edge One Pages 配置文件
// 用于自动化部署和配置管理

export default {
  // 项目基本信息
  name: 'github-docker-accel',
  description: 'GitHub 和 Docker 资源加速代理服务',
  
  // 构建配置
  build: {
    command: '',
    outputDir: 'static',
    publicDir: 'static'
  },
  
  // Functions 配置
  functions: {
    directory: 'functions',
    main: '_worker.js',
    runtime: 'edge-light'
  },
  
  // 路由配置
  routes: [
    {
      pattern: '/*',
      function: '_worker',
      methods: ['GET', 'POST', 'HEAD', 'OPTIONS']
    }
  ],
  
  // 环境变量
  env: {
    NODE_ENV: 'production'
  },
  
  // 头部配置
  headers: {
    '/*': {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Cache-Control': 'public, max-age=3600'
    },
    '/static/*': {
      'Cache-Control': 'public, max-age=86400'
    }
  },
  
  // 重定向配置
  redirects: [],
  
  // 重写配置
  rewrites: [
    {
      source: '/',
      destination: '/functions/_worker.js'
    }
  ]
};