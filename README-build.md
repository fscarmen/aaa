# cfnat C 多平台构建说明

本仓库当前维护三个入口文件：

- [`cfnat_linux.c`](cfnat_linux.c)：Linux 版本，已接入百度前置代理与运营商分池。
- [`cfnat_macos.c`](cfnat_macos.c)：macOS 版本，已按 Linux 主线对齐百度前置代理与运营商分池能力。
- [`cfnat_windows.c`](cfnat_windows.c)：Windows 7+ 版本，已按 Linux 主线重建百度前置代理与运营商分池逻辑，并补回 Winsock / Windows DNS 兼容层。

## 构建命令

### Linux

```bash
gcc -O2 -pthread ./cfnat_linux.c -o ./cfnat-linux -lresolv
```

说明：

- Linux 版本使用了 [`res_query()`](cfnat_linux.c:819) / [`ns_initparse()`](cfnat_linux.c:822) 这类 DNS TXT 查询能力做 ASN 识别。
- 因此链接时必须带上 `-lresolv`。

### macOS

```bash
clang -O2 -pthread ./cfnat_macos.c -o ./cfnat-macos -lresolv
```

说明：

- 适用于 amd64 和 arm64。
- macOS 版现在同样使用 DNS TXT / ASN 查询，因此链接时也需要带上 `-lresolv`。
- 功能面已与 [`cfnat_linux.c`](cfnat_linux.c) 保持同构。

### Windows（MinGW-w64）

```bash
gcc -O2 -o cfnat.exe ./cfnat_windows.c -lws2_32 -lwinpthread -ldnsapi -static
```

说明：

- 通过 `_WIN32_WINNT=0x0601` 支持 Windows 7 或更高版本。
- 使用 Winsock2 与 `winpthread`。
- Windows 版使用 [`DnsQuery_A()`](cfnat_windows.c:825) 做 TXT 查询，因此需要链接 `-ldnsapi`。

## 参数精简说明

目前三平台都已经移除 `-select` 参数，固定使用 `best` 作为连接选择策略。

Linux / macOS / Windows 三个平台现在都对齐为同一组参数面，并共享同一套百度前置代理与运营商分池开关语义。

其中三平台进一步把以下项改为源码顶部硬编码常量：

- 百度前置代理域名
- 百度前置代理端口
- 百度代理扫描目标
- 百度代理节点保留数量
- 运营商解析器配置

如果需要调整，直接修改 [`cfnat_linux.c`](cfnat_linux.c)、[`cfnat_macos.c`](cfnat_macos.c)、[`cfnat_windows.c`](cfnat_windows.c) 顶部默认常量即可。

## 仓库关键文件

```text
cfnat_linux.c
cfnat_macos.c
cfnat_windows.c
README.md
README-build.md
.github/workflows/build.yml
```
