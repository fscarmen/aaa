# qrencode（C 版本）

这是原 Go 版 `qrencode-go` 的 C 语言移植版。命令行参数和终端二维码渲染行为保持不变，发布产物统一命名为 `qrencode-linux-*`。

程序会在终端输出文本二维码，适合在脚本、SSH 终端或纯命令行环境中快速展示 URL / 文本内容。

## 功能特性

- 可执行文件名：`qrencode`
- 支持二维码纠错等级：`L`、`M`、`Q`、`H`
- 支持 quiet zone 边距设置
- 支持紧凑半高字符渲染
- Release 里的 Linux 二进制为静态链接构建，避免 `GLIBC_2.xx not found` 问题
- Release 里的二进制静态链接 `libqrencode`，运行时不需要额外安装 `libqrencode`

## 直接下载 Release 二进制

在 GitHub Release 中下载对应架构的文件，例如：

```text
qrencode-linux-amd64
qrencode-linux-386
qrencode-linux-armv5
qrencode-linux-armv6
qrencode-linux-armv7
qrencode-linux-arm64
qrencode-linux-mips
qrencode-linux-mipsel
qrencode-linux-mips64
qrencode-linux-mips64el
qrencode-linux-ppc64
qrencode-linux-ppc64le
qrencode-linux-riscv64
qrencode-linux-s390x
```

使用示例：

```bash
chmod +x qrencode-linux-amd64
./qrencode-linux-amd64 "https://example.com"
```

## 从源码本地编译

本地默认构建会动态加载系统 `libqrencode`，适合开发调试。

### Ubuntu / Debian

```bash
sudo apt-get update
sudo apt-get install -y build-essential libqrencode4
make
./qrencode "https://example.com"
```

### Fedora

```bash
sudo dnf install -y gcc make qrencode-libs
make
./qrencode "https://example.com"
```

### Arch Linux

```bash
sudo pacman -S --needed base-devel qrencode
make
./qrencode "https://example.com"
```

清理构建产物：

```bash
make clean
```

## 使用方法

```bash
./qrencode [options] <text>
```

### 参数

| 参数 | 说明 | 默认值 |
| --- | --- | --- |
| `-level L/M/Q/H` | 二维码纠错等级 | `L` |
| `-level=L/M/Q/H` | 等价写法 | `L` |
| `-qz int` | quiet zone 边距大小 | `1` |
| `-qz=int` | 等价写法 | `1` |
| `-compact` | 使用半高字符紧凑输出 | `true` |
| `-compact=true/false` | 开启或关闭紧凑输出 | `true` |

## 示例

```bash
./qrencode "https://example.com"
./qrencode -level H -qz 2 "https://example.com"
./qrencode -compact=false "hello world"
./qrencode -level=M -qz=1 -compact=true "hello world"
```

IPv6 URL 示例：

```bash
./qrencode "http://[2602:294:0:dc:1234:4321:7003:1]:64221/path"
```

## GitHub Actions

Workflow 文件：

```text
.github/workflows/build.yml
```

当推送 `v*` 标签时，Actions 会：

1. 为多个 Linux 架构交叉编译静态 `libqrencode`
2. 静态链接生成 `qrencode-linux-*` 二进制
3. 检查产物不是 dynamically linked
4. 将所有二进制上传为 workflow artifacts
5. 自动把所有 `qrencode-linux-*` 附加到 GitHub Release

手动运行 `workflow_dispatch` 时只会生成 artifacts；只有 tag 构建会上传到 Release。

发布新版本示例：

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 项目结构

```text
.
├── .github/
│   └── workflows/
│       ├── build.yml
├── Makefile
├── README.md
└── main.c
```
