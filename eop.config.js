module.exports = {
  routes: [
    // 静态资源
    {
      src: '^/static/(.*)$',
      headers: {
        'Cache-Control': 'public, max-age=31536000, immutable'
      },
      dest: '/static/$1'
    },
    // API 路由 - 所有非静态资源的请求都由边缘函数处理
    {
      src: '^/(.*)$',
      dest: '/functions/proxy.js'
    }
  ]
};