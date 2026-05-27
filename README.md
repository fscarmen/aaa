# better-cf-ip-c

`better-cf-ip-c` 是一个 C 语言实现的 Cloudflare IP 优选和测速工具。项目目标是保留原始交互式菜单体验，同时支持 Linux、macOS 和 Windows 构建。

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
| Linux | `linux-amd64` | 支持 | 使用 glibc、pthread、OpenSSL、libcurl。 |
| macOS Intel | `macos-amd64` | 支持 | 使用 Apple clang、Homebrew OpenSSL/libcurl。 |
| macOS Apple Silicon | `macos-arm64` | 支持 | 最低建议 macOS 11。 |
| Windows x64 | `windows-amd64` | 支持 | MinGW-w64/MSYS2，目标 Win7 SP1+。 |
| Windows x86 | `windows-386` | 支持 | 用于旧机器和旧系统。 |

> Windows 7 支持不是一句口号。源码使用 `_WIN32_WINNT=0x0601`，避免直接使用 Win8/Win10 专属 API；但最终是否能在真实 Win7 机器运行，还取决于 libcurl/OpenSSL 构建产物是否也兼容 Win7。

## 依赖

### Linux

Debian / Ubuntu：

```bash
sudo apt-get update
sudo apt-get install -y build-essential pkg-config libcurl4-openssl-dev libssl-dev
```

### macOS

```bash
brew install pkg-config openssl@3 curl
```

如果 `pkg-config` 找不到 Homebrew 的 OpenSSL 或 curl，可以手动设置：

```bash
export PKG_CONFIG_PATH="$(brew --prefix openssl@3)/lib/pkgconfig:$(brew --prefix curl)/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### Windows

推荐使用 MSYS2 MinGW-w64：

```bash
pacman -S --needed \
  mingw-w64-x86_64-gcc \
  mingw-w64-x86_64-pkgconf \
  mingw-w64-x86_64-curl \
  mingw-w64-x86_64-openssl \
  mingw-w64-x86_64-winpthreads
```

32 位构建把 `x86_64` 换成 `i686`。

## 编译

### 默认编译 Linux amd64

```bash
make
```

输出：

```text
better-cf-ip-c
```

### 交互式选择版本

```bash
./scripts/build.sh
```

默认目标是 `linux-amd64`。也可以直接指定：

```bash
./scripts/build.sh linux-amd64
./scripts/build.sh macos-amd64
./scripts/build.sh macos-arm64
./scripts/build.sh windows-amd64
./scripts/build.sh windows-386
```

产物输出到 `dist/`。

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

## Windows 控制台、字体和编码

Windows 版本启动后会调用：

- `WSAStartup(MAKEWORD(2, 2), ...)`
- `SetConsoleOutputCP(CP_UTF8)`
- `SetConsoleCP(CP_UTF8)`

建议控制台字体：

- 英文环境：`Consolas` 或 `Lucida Console`
- 中文环境：`新宋体 / NSimSun`、`Microsoft YaHei Mono` 或其他支持中文的等宽字体

为了兼容 Win7，不在默认输出中使用 emoji、复杂框线和私有字体。项目不打包字体文件，避免字体版权问题。

## GitHub Actions

仓库内置 `.github/workflows/build.yml`。手动触发时可以选择：

- `linux-amd64`
- `macos-amd64`
- `macos-arm64`
- `windows-amd64`
- `windows-386`
- `all-supported`

打 tag，例如 `v2.0.0`，会自动打包 Release 并生成 SHA256 校验文件。

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

- Linux 容器内只能验证 Linux 构建和基础启动流程。
- Windows Win7 兼容必须用真实 Win7 SP1 或对应虚拟机最终验收。
- macOS 通用二进制没有默认合并；当前按 `macos-amd64` 和 `macos-arm64` 分开输出。
