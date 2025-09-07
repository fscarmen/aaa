module.exports = {
  routes: [
    // 首页路由
    {
      src: '^/$',
      dest: '/static/index.html'
    },
    // 静态资源
    {
      src: '^/static/(.*)$',
      headers: {
        'Cache-Control': 'public, max-age=31536000, immutable'
      },
      dest: '/static/$1'
    },
    // API 路由 - 所有其他请求都由边缘函数处理
    {
      src: '^/(.*)$',
      dest: '/functions/proxy.js'
    }
  ]
};