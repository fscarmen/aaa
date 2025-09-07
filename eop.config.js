module.exports = {
  routes: [
    // 首页路由
    {
      src: '^/$',
      dest: '/static/index.html'
    },
    // 调试页面路由
    {
      src: '^/debug.html$',
      dest: '/static/debug.html'
    },
    // 静态资源
    {
      src: '^/static/(.*)$',
      headers: {
        'Cache-Control': 'public, max-age=31536000, immutable'
      },
      dest: '/static/$1'
    },
    // 所有其他请求都由边缘函数处理
    {
      src: '^/(.*)',
      dest: '/functions/proxy.js'
    }
  ]
};