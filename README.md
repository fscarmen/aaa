# cfnat C 版

面向低内存环境的 **Cloudflare IP 扫描 + 单端口 TCP 转发** 工具。

C 版基于 [`cfnat.go`](cfnat.go) 移植，目标不是把功能做得更复杂，而是在保留扫描、优选、转发、健康检查、百度前置代理和运营商分池等核心能力的同时，尽量降低常驻内存占用，适合 OpenWrt、路由器、小内存 VPS、ARM 小板机等资源受限环境。

---

## 目录

- [项目定位](#项目定位)
- [核心特性](#核心特性)
- [快速开始](#快速开始)
- [运行参数](#运行参数)
- [常用示例](#常用示例)
- [工作原理](#工作原理)
- [百度前置代理与运营商分池](#百度前置代理与运营商分池)
- [构建与发布](#构建与发布)
- [仓库文件说明](#仓库文件说明)
- [数据文件说明](#数据文件说明)
- [日志与排错](#日志与排错)
- [资源占用说明](#资源占用说明)
- [常见问题](#常见问题)
- [免责声明](#免责声明)

---

## 项目定位

cfnat C 版做三件事：

1. 扫描 Cloudflare IP，按数据中心、延迟、丢包率筛出候选节点。
2. 在本机监听一个 TCP 端口，自动识别 TLS / 非 TLS 流量。
3. 把客户端连接转发到当前可用的 Cloudflare 优选 IP，并在失败时自动切换。

它不是 HTTP 反向代理，也不会解密或篡改业务数据。它只做 TCP 字节转发。

典型链路：

```text
客户端
  ↓
cfnat 本地监听端口
  ↓
Cloudflare 优选 IP:443 或 :80
```

启用百度前置代理时：

```text
客户端
  ↓
cfnat 本地监听端口
  ↓
百度前置节点（HTTP CONNECT）
  ↓
Cloudflare 优选 IP:443 或 :80
```

---

## 核心特性

- 支持 IPv4 / IPv6 扫描入口。
- 支持 IPv4 / IPv6 监听地址。
- 支持按 Cloudflare 数据中心过滤，例如 `HKG`、`SJC`、`LAX`。
- 候选 IP 按延迟和丢包率综合评分。
- 候选 IP 按延迟和丢包率综合评分，始终使用当前 score 最低的最优 IP。
- 单端口同时承接 TLS 与非 TLS / HTTP 流量。
- 根据客户端首字节自动分流到 `-port` 或 `-http-port`。
- 支持定时健康检查与失败自动切换。
- 支持百度前置代理。
- 支持运营商分池监听，可按移动、电信、联通分别建立监听入口。
- Linux / macOS / Windows 三平台实现。
- Linux / macOS 使用 `pthread` + POSIX/BSD socket。
- Windows 使用 Winsock2 + Windows DNS API + MinGW-w64 `winpthread`。
- 统一日志级别：`silent`、`error`、`warn`、`info`、`debug`。

---

## 快速开始

### 1. 本地编译

Linux：

```bash
gcc -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_linux.c -o ./cfnat-linux \
  -pthread -lresolv
```

macOS：

```bash
clang -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_macos.c -o ./cfnat-macos \
  -pthread -lresolv
```

Windows（MinGW-w64）：

```bash
x86_64-w64-mingw32-gcc \
  -O2 -pipe -std=c11 -D_WIN32_WINNT=0x0601 \
  -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_windows.c -o ./cfnat.exe \
  -lws2_32 -ldnsapi -lwinpthread -static -s
```

### 2. 启动

Linux 示例：

```bash
./cfnat-linux -addr=0.0.0.0:40000 -colo=HKG -delay=80 -random=false
```

macOS 示例：

```bash
./cfnat-macos -addr=0.0.0.0:40000 -colo=HKG -delay=80 -random=false
```

Windows 示例：

```bash
cfnat.exe -addr=0.0.0.0:40000 -colo=HKG -delay=80 -random=false
```

### 3. 客户端访问

客户端统一连接同一个端口：

```text
服务器IP:40000
```

程序会自动识别连接类型：

```text
TLS 流量           → Cloudflare IP:443
非 TLS / HTTP 流量 → Cloudflare IP:80
```

---

## 运行参数

| 参数 | 说明 | 默认值 |
| --- | --- | --- |
| `-addr` | 本地监听地址，例如 `0.0.0.0:1234` 或 `[::]:1234` | `0.0.0.0:1234` |
| `-colo` | Cloudflare 数据中心过滤，多个用逗号分隔，例如 `HKG,SJC,LAX` | 空 |
| `-delay` | 有效延迟阈值，单位毫秒 | `300` |
| `-ipnum` | 保留的候选 IP 数量 | `20` |
| `-ips` | 扫描 IPv4 或 IPv6，取值 `4` 或 `6` | `4` |
| `-num` | 每个客户端连接的目标连接尝试次数 | `5` |
| `-port` | TLS 流量转发目标端口 | `443` |
| `-http-port` | 非 TLS / HTTP 流量转发目标端口 | `80` |
| `-random` | 是否从 CIDR 随机抽样 IP | `true` |
| `-task` | 扫描线程数，上限为 `512` | `100` |
| `-code` | HTTP / HTTPS 探测期望状态码 | `200` |
| `-domain` | 健康检查目标域名与路径 | `cloudflaremirrors.com/debian` |
| `-health-log` | 健康检查成功日志输出间隔，单位秒；设为 `0` 可关闭成功日志 | `60` |
| `-log` | 日志级别：`silent`、`error`、`warn`、`info`、`debug` | `info` |
| `-baidu-proxy` | 是否启用百度前置代理 | `false` |
| `-carrier-listens` | 运营商分池监听配置 | 空 |

### 已固定为源码常量的项目

为了减少参数污染，以下配置不再作为命令行参数暴露，而是放在三个 C 源文件顶部：

| 配置 | 源码常量 |
| --- | --- |
| 百度前置代理域名 | `DEFAULT_BAIDU_DOMAIN` |
| 百度前置代理端口 | `DEFAULT_BAIDU_PORT` |
| 百度代理扫描目标 | `DEFAULT_BAIDU_SCAN_TARGET` |
| 每个百度代理池保留节点数 | `DEFAULT_BAIDU_IPNUM` |
| 运营商解析器配置 | `DEFAULT_CARRIER_RESOLVERS` |

需要调整这些值时，直接修改对应平台源码顶部的默认常量：

```text
cfnat_linux.c
cfnat_macos.c
cfnat_windows.c
```

---

## 常用示例

### 扫描香港机房并监听单端口

```bash
./cfnat-linux -addr=0.0.0.0:40000 -colo=HKG -delay=80 -random=false
```

### 同时接受多个数据中心

```bash
./cfnat-linux -addr=0.0.0.0:40000 -colo=HKG,SJC,LAX -delay=120
```

### 使用 IPv6 扫描源

```bash
./cfnat-linux -addr=[::]:40000 -ips=6 -colo=HKG -delay=120
```

### 打开调试日志

```bash
./cfnat-linux -log=debug
```

### 提高候选池规模和扫描并发

```bash
./cfnat-linux -ipnum=50 -task=200
```

### 启用百度前置代理

```bash
./cfnat-linux -baidu-proxy=true -addr=0.0.0.0:40000 -colo=HKG
```

### 启用运营商分池监听

```bash
./cfnat-linux \
  -baidu-proxy=true \
  -carrier-listens="mobile=0.0.0.0:1234,telecom=0.0.0.0:1235,unicom=0.0.0.0:1236"
```

分池模式下，可以给不同运营商分配不同本地入口：

```text
移动用户 → 服务器IP:1234
电信用户 → 服务器IP:1235
联通用户 → 服务器IP:1236
```

---

## 工作原理

### 1. 加载 IP 段

程序启动后根据 `-ips` 选择 IPv4 或 IPv6 扫描源：

```text
-ips=4 → IPv4
-ips=6 → IPv6
```

本地数据文件不存在时，会尝试自动下载。

### 2. 生成待测 IP

根据 `-random` 决定扫描方式：

```text
-random=true   从每个 CIDR 随机抽取 IP
-random=false  展开 CIDR 后按顺序测试
```

### 3. TCP 连通性测试

对待测 IP 发起 TCP 连接测试，并记录建连耗时。

这个耗时会作为基础延迟，后续用于候选评分。

### 4. 识别 Cloudflare 数据中心

程序向目标 IP 发起 HTTP 探测，并从响应头中读取 `CF-RAY`。

示例：

```text
xxxx-HKG
xxxx-SJC
xxxx-LAX
```

后缀就是 Cloudflare 数据中心代码。程序会结合 `locations.json` 映射地区与城市信息。

### 5. 按 `-colo` 过滤

如果指定：

```bash
-colo=HKG,SJC,LAX
```

程序只保留匹配这些数据中心的结果。

不指定 `-colo` 时，不按数据中心过滤。

### 6. 综合评分

候选 IP 会根据延迟和丢包率计算综合分，分数越低越优。

可以近似理解为：

```text
score = latency * 10 + loss_rate * 25
```

所以程序不是单纯选择最低延迟，而是同时考虑速度和稳定性。

### 优选原则

程序没有多套选择逻辑，只有一套固定的自动优选逻辑：

```text
扫描候选
→ 按 score 排序
→ 永远取 score 最低的 IP
→ 健康检查失败
→ 切换到下一个最优候选
→ 候选池耗尽后重新扫描并重新排序
```

这个模型可以避免轮询或随机选择带来的链路漂移，让行为更稳定、代码更简单。

### 7. 健康检查

程序会对候选 IP 做目标端口健康检查。

只有健康检查通过的 IP 才会成为当前转发 IP。

### 8. 自动切换

运行期间会定时检查当前 IP。

当当前 IP 连续失败两次后，程序会切换到下一个可用候选；如果候选池耗尽，会重新扫描。

### 9. 单端口自动分流

客户端只需要连接同一个本地端口。程序接收连接后读取客户端首字节：

```text
首字节是 0x16 → 认为是 TLS 流量
其他情况      → 认为是非 TLS / HTTP 流量
```

然后转发到不同目标端口：

```text
TLS 流量           → Cloudflare IP:-port
非 TLS / HTTP 流量 → Cloudflare IP:-http-port
```

默认等价于：

```text
TLS 流量           → Cloudflare IP:443
非 TLS / HTTP 流量 → Cloudflare IP:80
```

---

## 百度前置代理与运营商分池

### 百度前置代理

启用 `-baidu-proxy=true` 后，扫描和转发会通过百度前置节点建立 HTTP CONNECT 链路。

简化链路：

```text
客户端
  ↓
cfnat
  ↓
百度前置节点
  ↓
Cloudflare IP
```

这个模式适合本机直连 Cloudflare 不稳定、但经前置节点链路更稳定的网络环境。

注意：百度前置代理不是万能加速器。它的价值在于让扫描路径和实际转发路径尽量一致，减少“扫得通但转发不稳”的偏差。

### 运营商分池

启用 `-carrier-listens` 后，程序可以按运营商建立独立监听入口和独立候选池。

示例：

```bash
-carrier-listens="mobile=0.0.0.0:1234,telecom=0.0.0.0:1235,unicom=0.0.0.0:1236"
```

典型用途：

- 移动、电信、联通到前置节点的路径差异明显。
- 单一候选池容易出现某个运营商可用、另一个运营商劣化。
- 想给不同入口分别维护更贴近各自网络路径的候选 IP。

---

## 构建与发布

本仓库当前维护三个 C 入口文件：

| 平台 | 源文件 | 主要依赖 |
| --- | --- | --- |
| Linux | [`cfnat_linux.c`](cfnat_linux.c) | `pthread`、POSIX socket、`resolv` |
| macOS | [`cfnat_macos.c`](cfnat_macos.c) | `pthread`、BSD socket、`resolv` |
| Windows | [`cfnat_windows.c`](cfnat_windows.c) | Winsock2、Windows DNS API、`winpthread` |


### Linux 发布版本选择

Release 同时提供两类 Linux 文件：

| 类型 | 适合用户 | 说明 |
| --- | --- | --- |
| glibc 动态版 | Debian、Ubuntu、Arch、CentOS、Fedora 等常规发行版 | 默认推荐，运行时使用系统自己的 glibc，避免静态 glibc 与系统环境错位 |
| musl 静态版 | Alpine、OpenWrt、ImmortalWrt、极简容器、小内存系统 | 完全静态，更适合轻量系统和无 glibc 环境 |

glibc fully-static 在部分发行版和新内核环境下可能出现 resolver、pthread、NSS、IPv6 或 DNS 初始化兼容问题，因此不再作为默认发布产物。需要完全静态时，请优先使用 musl 静态版。

### Linux 构建

```bash
gcc -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_linux.c -o ./cfnat-linux \
  -pthread -lresolv
```

如需尽量静态链接：

```bash
gcc -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_linux.c -o ./cfnat-linux \
  -pthread -lresolv
```

说明：

- Linux glibc 动态版使用 DNS TXT 查询做 ASN / 运营商识别。
- 因此 glibc 动态版链接时必须带上 `-lresolv`。
- 不推荐发布 glibc fully-static 版本；完全静态请使用 musl。

Musl 静态版示例：

```bash
x86_64-linux-musl-gcc -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_linux.c -o ./cfnat-linux-amd64-musl \
  -pthread -static -s
```

说明：musl 的 resolver 通常在 libc 内，不需要额外链接 glibc 的 `-lresolv`。


### macOS 构建

```bash
clang -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_macos.c -o ./cfnat-macos \
  -pthread -lresolv
```

交叉指定架构示例：

```bash
clang -O2 -pipe -std=c11 \
  -arch x86_64 -mmacosx-version-min=10.13 \
  ./cfnat_macos.c -o ./cfnat-darwin-amd64 \
  -pthread -lresolv
```

```bash
clang -O2 -pipe -std=c11 \
  -arch arm64 -mmacosx-version-min=11.0 \
  ./cfnat_macos.c -o ./cfnat-darwin-arm64 \
  -pthread -lresolv
```

说明：

- macOS amd64 最低目标可设为 `10.13`。
- macOS arm64 最低目标通常设为 `11.0`，因为 Apple Silicon 从 macOS 11 开始支持。
- macOS 不支持像 Linux musl 那样生成完全静态的系统 libc 二进制。
- macOS 版同样使用 DNS TXT / ASN 查询，因此也需要 `-lresolv`。


### Windows 中文显示

Windows 版程序启动时会自动切换控制台输入/输出为 UTF-8，并设置 UTF-8 locale，用于避免中文日志乱码。

如果仍然出现乱码，建议使用 Windows Terminal 或 PowerShell。传统 CMD 可手动执行：

```cmd
chcp 65001
```

推荐字体：Consolas、Cascadia Mono、Lucida Console。

### Windows 构建

64 位：

```bash
x86_64-w64-mingw32-gcc \
  -O2 -pipe -std=c11 -D_WIN32_WINNT=0x0601 \
  -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_windows.c -o ./cfnat-windows-amd64.exe \
  -lws2_32 -ldnsapi -lwinpthread -static -s
```

32 位：

```bash
i686-w64-mingw32-gcc \
  -O2 -pipe -std=c11 -D_WIN32_WINNT=0x0601 \
  -Wall -Wextra -Wno-unused-parameter \
  ./cfnat_windows.c -o ./cfnat-windows-386.exe \
  -lws2_32 -ldnsapi -lwinpthread -static -s
```

说明：

- `_WIN32_WINNT=0x0601` 表示目标为 Windows 7 或更高版本。
- Windows 网络层使用 Winsock2，因此需要 `-lws2_32`。
- Windows TXT 查询使用 `DnsQuery_A()` / `DnsFree()`，因此需要 `-ldnsapi`。
- Windows 线程兼容层使用 MinGW-w64 `winpthread`，因此需要 `-lwinpthread`。

### GitHub Actions

多平台构建工作流位于：

```text
.github/workflows/build.yml
```

当前工作流包含：

- Linux：amd64、386、armv5、armv6、armv7、arm64、mips、mipsel、mips64、mips64el、ppc64、ppc64le、riscv64、s390x、loongarch64。
- Windows：amd64、386。
- macOS：amd64、arm64。
- tag 触发发布：推送 `v*` 标签后打包 release 文件和校验和。
- 手动触发：支持 `workflow_dispatch`。

发布包会把二进制文件放入 `bin/`，并附带源码、README 和基础数据文件。

### 常见构建失败

| 现象 | 原因 | 修复 |
| --- | --- | --- |
| macOS 出现 `_res_9_query`、`_res_9_ns_initparse`、`_res_9_ns_parserr` undefined symbols | 没有链接 resolver 库 | 在链接参数末尾加 `-lresolv` |
| Linux 出现 `res_query`、`ns_initparse`、`ns_parserr` undefined reference | 没有链接 resolver 库 | 在链接参数末尾加 `-lresolv` |
| Windows 出现 `undefined reference to DnsQuery_A` / `DnsFree` | 没有链接 Windows DNS API | 在链接参数末尾加 `-ldnsapi` |
| Windows 出现 Winsock 相关 undefined reference | 没有链接 Winsock2 | 加 `-lws2_32` |
| 出现 `choose_name`、`parse_choose_value`、`choose_summary` unused warning | 遗留辅助函数未被调用 | 不影响链接；追求干净日志时可删除遗留函数 |
| Windows 出现 `SOCKET` 与 `< 0` / `>= 0` 比较 warning | Windows `SOCKET` 是无符号类型，应使用 `INVALID_SOCKET` 判断 | 不一定导致编译失败；如开启 `-Werror` 需修正判断方式 |

---

## 仓库文件说明

```text
cfnat.go                         Go 版实现 / 参考实现
cfnat-origin.go                  原始 Go 版留档
cfnat_linux.c                    Linux C 版入口
cfnat_macos.c                    macOS C 版入口
cfnat_windows.c                  Windows C 版入口
ips-v4                           上游 IPv4 数据文件
ips-v6                           上游 IPv6 数据文件
locations                        上游 Cloudflare 数据中心位置文件
README.md                        主说明文档
.github/workflows/build.yml      C 版多平台构建工作流
.github/workflows/build_go.yml   Go 版构建工作流
```

`README-build.md` 已合并进本文件，不再单独维护，避免构建说明和主文档互相漂移。

---

## 数据文件说明

源码运行时会查找以下本地文件：

```text
ips-v4.txt
ips-v6.txt
locations.json
```

如果文件不存在，程序会自动从上游地址下载并保存为上述文件名。

仓库中也可能保留上游原始数据文件：

```text
ips-v4
ips-v6
locations
```

离线运行时可以手动复制：

```bash
cp ips-v4 ips-v4.txt
cp ips-v6 ips-v6.txt
cp locations locations.json
```

这样可以避免启动时依赖网络下载基础数据。

---

## 日志与排错

### 日志级别

```text
-log=silent  不输出普通日志
-log=error   仅输出错误
-log=warn    输出警告和错误
-log=info    输出常规运行日志
-log=debug   输出调试信息
```

### 正常日志示例

```text
可用 IP: 104.18.x.x (健康检查端口:443)
正在监听 0.0.0.0:40000，TLS目标端口：443，非TLS目标端口：80
状态检查成功: 当前 IP 104.18.x.x 可用
```

### 自动切换日志示例

```text
状态检查失败 (1/2): 当前 IP 104.18.x.x 暂不可用
连续两次状态检查失败，切换到下一个 IP
切换到下一个最优 IP: 104.18.x.x 候选索引: 3
```

### 没有扫到有效 IP

```text
未发现有效IP，可尝试放宽 -delay 或提高 -log=debug 查看细节，3 秒后重试
```

建议按下面顺序排查：

1. 放宽延迟限制，例如 `-delay=300` 或更高。
2. 暂时去掉 `-colo`，确认不是数据中心过滤过严。
3. 使用 `-random=false` 做更完整的 CIDR 扫描。
4. 提高扫描并发，例如 `-task=200`。
5. 开启 `-log=debug` 查看失败阶段。
6. 网络直连 Cloudflare 不稳定时，尝试 `-baidu-proxy=true`。

---

## 资源占用说明

C 版的核心价值是降低常驻资源占用。

相较于 Go 版，C 版没有 Go 运行时、GC 和 goroutine 调度器的额外常驻成本，并在实现上做了更保守的资源控制：

- 双向转发缓冲区固定为 `16 KB`。
- 每个转发方向使用固定缓冲区。
- 连接线程使用较小栈空间。
- 候选结果只保留必要字段。
- 使用原生 `pthread` / Winsock / BSD socket。
- 健康检查逻辑固定频率执行，不引入复杂后台状态机。

更适合：

- OpenWrt / ImmortalWrt 路由器。
- 小内存 VPS。
- ARM 小板机。
- 需要长期驻留的网络中转环境。
- 连接数波动较大但希望内存可控的场景。

Go 版仍然适合快速开发、维护和功能扩展；C 版更适合资源受限和长期常驻。

---

## 常见问题

### 1. 为什么只监听一个端口，却能同时处理 TLS 和非 TLS？

程序读取客户端连接的首字节：

```text
0x16 → TLS
其他 → 非 TLS / HTTP
```

然后分别转发到 `-port` 和 `-http-port`。

### 2. `-choose` 参数去哪了？

当前三平台固定使用综合评分最低的候选 IP，不再暴露 `-choose` 参数。

这样可以减少参数复杂度，也避免三平台行为不一致。

### 3. 百度前置代理一定更快吗？

不一定。

它主要解决的是部分网络环境下直连 Cloudflare 不稳定的问题。是否更快取决于本机、前置节点、Cloudflare IP 三者之间的实际链路。

### 4. 运营商分池什么时候有必要启用？

当移动、电信、联通到 Cloudflare 或百度前置节点的路径差异明显时，分池更有意义。

如果你的用户来源单一，或者不同运营商表现差异不大，可以不启用。

### 5. C 版是不是功能一定比 Go 版强？

不是。

C 版的优势是低内存和更可控的运行时开销。Go 版在开发效率、可维护性和扩展速度上仍然更有优势。

### 6. 为什么编译能过，但运行时提示找不到 IP 文件？

C 源码运行时默认查找 `ips-v4.txt`、`ips-v6.txt` 和 `locations.json`。

如果当前目录只有 `ips-v4`、`ips-v6`、`locations`，请手动复制为源码期望的文件名，或允许程序联网自动下载。

---

## 免责声明

本工具仅用于网络测试与学习用途。

请在合法、合规的网络环境下使用。使用者需要自行承担因错误配置、滥用或违反当地法律法规造成的后果。
