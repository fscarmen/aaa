# better-cf-ip-c

`better-cf-ip-c` 是一个 C 语言实现的 Cloudflare IP 优选和测速工具。项目目标是保留原始交互式菜单体验，同时支持 Linux、Linux musl、macOS 和 Windows 构建。

## 功能

- IPv4 / IPv6 优选。
- TLS / 非 TLS RTT 检测。
- 单 IP 下载测速。
- 自动下载并缓存 IP 列表、测速 URL 和机房位置数据。
- 支持通过 `BETTER_CF_IP_DATA_DIR` 或 `--data-dir` 指定数据目录。
- Windows 启动时自动初始化 WinSock，并把控制台输入输出切换为 UTF-8。

## 平台支持

| 平台 | 目标 | 状态 | 说明 |
| --- | --- | --- | --- |
| Linux glibc x64 | `linux-amd64` | 支持 | Ubuntu runner 原生构建。 |
| Linux glibc ARM64 | `linux-arm64` | 支持 | Ubuntu ARM64 容器/QEMU 构建。 |
| Linux musl x64 | `linux-amd64-musl` | 支持 | Alpine musl 构建。 |
| Linux musl ARM64 | `linux-arm64-musl` | 支持 | Alpine ARM64 musl 容器/QEMU 构建。 |
| macOS Intel | `macos-amd64` | 支持 | Apple clang、Homebrew OpenSSL/libcurl，runner 使用 `macos-13`。 |
| macOS Apple Silicon | `macos-arm64` | 支持 | 最低建议 macOS 11，runner 使用 `macos-14-arm64`。 |
| Windows x64 | `windows-amd64` | 支持 | MSYS2 MINGW64，目标 Win7 SP1+。 |
| Windows x86 | `windows-386` | 支持 | MSYS2 MINGW32，用于旧机器和旧系统，目标 Win7 SP1+。 |
| Windows ARM64 | `windows-arm64` | 支持编译 | MSYS2 CLANGARM64。注意：Windows ARM64 不支持 Win7，目标是 Windows 10/11 ARM64。 |

> Windows 7 支持只覆盖 `windows-amd64` 和 `windows-386`。`windows-arm64` 没有 Win7 这个系统形态，别把它们混在一起。

## 依赖

### Linux glibc

Debian / Ubuntu：

```bash
sudo apt-get update
sudo apt-get install -y build-essential pkg-config libcurl4-openssl-dev libssl-dev
```

### Linux musl

Alpine：

```bash
apk add --no-cache build-base pkgconf curl-dev openssl-dev linux-headers ca-certificates
```

当前 musl 目标使用 Alpine musl 工具链构建，不强制完全静态链接。强行静态链接 libcurl/OpenSSL 会牵出 zlib、nghttp2、brotli、zstd 等依赖，容易把 CI 搞成玄学现场。

### macOS

```bash
brew install pkg-config openssl@3 curl
```

如果 `pkg-config` 找不到 Homebrew 的 OpenSSL 或 curl，可以手动设置：

```bash
export PKG_CONFIG_PATH="$(brew --prefix openssl@3)/lib/pkgconfig:$(brew --prefix curl)/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### Windows x64 / x86

推荐使用 MSYS2 MinGW-w64。x64：

```bash
pacman -S --needed \
  mingw-w64-x86_64-gcc \
  mingw-w64-x86_64-pkgconf \
  mingw-w64-x86_64-curl \
  mingw-w64-x86_64-openssl \
  mingw-w64-x86_64-winpthreads
```

32 位构建把 `x86_64` 换成 `i686`。

### Windows ARM64

MSYS2 CLANGARM64：

```bash
pacman -S --needed \
  mingw-w64-clang-aarch64-clang \
  mingw-w64-clang-aarch64-pkgconf \
  mingw-w64-clang-aarch64-curl \
  mingw-w64-clang-aarch64-openssl \
  mingw-w64-clang-aarch64-winpthreads
```

## 编译

### 默认编译 Linux amd64

```bash
make
```

输出：

```text
better-cf-ip-c
```

### GitHub Actions 选择版本

本项目不使用 `scripts/build.sh`。所有平台构建逻辑都直接写在 `.github/workflows/build.yml` 里，避免脚本权限、换行和 shell 环境差异导致失败。

手动运行 workflow 时可以选择：

- `linux-amd64`
- `linux-arm64`
- `linux-amd64-musl`
- `linux-arm64-musl`
- `macos-amd64`
- `macos-arm64`
- `windows-amd64`
- `windows-386`
- `windows-arm64`
- `all-linux`
- `all-linux-musl`
- `all-macos`
- `all-windows`
- `all-supported`

产物输出到 workflow artifact；打 tag 时会自动进入 Release。

## 运行

```bash
./better-cf-ip-c
```

指定数据目录：

```bash
BETTER_CF_IP_DATA_DIR=./data ./better-cf-ip-c
```

或：

```bash
./better-cf-ip-c --data-dir ./data
```

Windows：

```powershell
.\better-cf-ip-c-windows-amd64.exe
```

## Windows 控制台、字体和编码

Windows 版本启动后会调用：

- `WSAStartup(MAKEWORD(2, 2), ...)`
- `SetConsoleOutputCP(CP_UTF8)`
- `SetConsoleCP(CP_UTF8)`

建议控制台字体：

- 英文环境：`Consolas` 或 `Lucida Console`
- 中文环境：`新宋体 / NSimSun`、`Microsoft YaHei Mono` 或其他支持中文的等宽字体

为了兼容 Win7，默认输出不使用 emoji、复杂框线和私有字体。项目不打包字体文件，避免字体版权问题。

## GitHub Actions

仓库内置 `.github/workflows/build.yml`。打 tag，例如 `v2.0.0`，会自动打包 Release 并生成 SHA256 校验文件。

## C 语言排版规范

本项目代码遵循以下规则：

- 缩进使用 4 个空格。
- 函数左花括号与函数声明同行。
- `if`、`for`、`while` 后保留一个空格。
- 宏和平台兼容代码集中放在文件顶部。
- 平台差异用 `_WIN32` 条件编译包住，不在业务逻辑里到处散落系统 API。
- 错误路径直接返回，不写多层无意义嵌套。

## 清理

```bash
make clean
rm -rf dist
```

## 已知限制

- 当前本地 Linux 环境只能验证 Linux amd64 构建和基础启动流程。
- Windows Win7 兼容必须用真实 Win7 SP1 或对应虚拟机最终验收。
- `windows-arm64` 只面向 Windows 10/11 ARM64，不承诺 Win7。
- macOS 通用二进制没有默认合并；当前按 `macos-amd64` 和 `macos-arm64` 分开输出。
- musl 版本使用 Alpine musl 构建，不默认承诺完全静态链接。

## GitHub Actions 常见问题

### 为什么没有 `scripts/build.sh`

为了让仓库在 GitHub Actions 上更稳，构建命令全部内联在 `.github/workflows/build.yml`。这样不会再出现 `Permission denied`、CRLF 换行、可执行位丢失等脚本类问题。

### Windows 为什么要单独处理 `setsockopt` / `getsockopt`

WinSock 的 `setsockopt` 第 4 个参数类型是 `const char *`，`getsockopt` 第 4 个参数类型是 `char *`；POSIX 则接受 `void *` / `int *` 这种写法。源码里已经通过 `bcf_setsockopt_int()` 和 `bcf_getsockopt_int()` 封装掉这个差异，不要再把裸 `int *` 直接传给 WinSock。

### macos-amd64 不要跑在 macos-14-arm64 上

`macos-amd64` 必须使用 Intel runner，例如 `macos-13`。如果在 `macos-14-arm64` 上用 Homebrew 的 `/opt/homebrew` 依赖去链接 x86_64，下一步会遇到架构不匹配。当前 workflow 已经把：

- `macos-amd64` 固定到 `macos-13`
- `macos-arm64` 固定到 `macos-14-arm64`
