# cfnat C 版

这是 cfnat 的 C 语言低内存重构 MVP，优先面向 Linux 路由器、OpenWrt、ImmortalWrt 和 VPS。

## 支持架构

- linux-amd64
- linux-arm64
- linux-armv5
- linux-armv6
- linux-armv7

## 功能

- Cloudflare IPv4 扫描
- 本地缺失 IP 文件时自动下载
- jsDelivr + GitHub raw fallback
- locations.json 机房数据解析
- 通过 CF-RAY 识别数据中心
- -colo=HKG 数据中心过滤
- 按 TCP 延迟排序
- 自动选择可用 IP
- 状态检查失败后自动切换 IP
- 单端口同时支持 TLS / 非 TLS
- TLS 流量转发到 -port=443
- 非 TLS 流量转发到 -http-port=80
- 精简日志
- 可选调试日志

## 使用

```bash
chmod +x cfnat-linux-arm64
./cfnat-linux-arm64 -addr=0.0.0.0:40000 -colo=HKG -delay=80 -random=false
```

## 参数

| 参数 | 默认值 | 说明 |
|---|---:|---|
| -addr=0.0.0.0:40000 | 0.0.0.0:1234 | 本地监听地址 |
| -colo=HKG | 空 | 指定 Cloudflare 数据中心 |
| -delay=80 | 300 | TCP 连接延迟阈值，毫秒 |
| -random=false | true | 是否从 CIDR 中随机抽取 IP |
| -ipnum=20 | 20 | 保留候选 IP 数量 |
| -task=100 | 100 | 扫描线程数 |
| -num=5 | 5 | 每个客户端连接的目标连接尝试次数 |
| -port=443 | 443 | TLS 目标端口 |
| -http-port=80 | 80 | 非 TLS / HTTP 目标端口 |
| -verbose=true | false | 打印详细日志 |
| -log-conn=true | false | 打印连接日志 |

## 工作原理

cfnat 只监听一个本地端口。

```text
客户端 -> cfnat 本地端口 -> Cloudflare 优选 IP
```

连接进入后，读取首字节判断协议：

```text
0x16 -> TLS 流量    -> Cloudflare IP:443
其他 -> 非 TLS 流量 -> Cloudflare IP:80
```

程序不解密 TLS，不修改 HTTP 内容，只做 TCP 透传。

## 构建

```bash
make
```

手动编译：

```bash
gcc -O2 -Wall -Wextra -std=c11 -pthread -o cfnat cfnat.c
```

## 当前边界

当前 C 版本是第一阶段 MVP，优先保证低内存、Linux arm/amd 可用和核心转发逻辑。IPv6 参数保留，但第一阶段主要优化 IPv4 路径。
