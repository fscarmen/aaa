# qrencode（C 版本）

这是原 Go 版 `qrencode-go` 的 C 语言移植版。当前命令名已改为 `qrencode`，Release / CI 产物统一使用 `qrencode-linux-*` 命名。

程序会在终端输出文本二维码，适合在脚本、SSH 终端或纯命令行环境中快速展示 URL / 文本内容。

## 功能特性

- 命令行用法：`qrencode [options] <text>`
- 支持二维码纠错等级：`L`、`M`、`Q`、`H`
- 支持 quiet zone 边距设置
- 支持紧凑半高字符渲染
- 无 Go 运行时依赖
- QR 矩阵生成使用系统 `libqrencode`，终端渲染逻辑由 C 实现
- GitHub Actions 支持多 Linux 架构构建

## 依赖

运行时需要安装 `libqrencode`。

### Ubuntu / Debian

```bash
sudo apt-get update
sudo apt-get install -y libqrencode4
```

如需从源码编译：

```bash
sudo apt-get update
sudo apt-get install -y build-essential libqrencode4
```

### Fedora

```bash
sudo dnf install -y gcc make qrencode-libs
```

### Arch Linux

```bash
sudo pacman -S --needed base-devel qrencode
```

## 编译

```bash
make
```

生成可执行文件：

```bash
./qrencode
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

## GitHub Actions 多平台构建

Workflow 文件：

```text
.github/workflows/build.yml
```

触发方式：

- push 到 `main` / `master`
- pull request 到 `main` / `master`
- tag：`v*`
- 手动 `workflow_dispatch`

构建产物命名均以 `qrencode` 开头：

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
qrencode-linux-loongarch64
```

> 注意：当前程序通过 `dlopen` 动态加载系统 `libqrencode.so.4` 或 `libqrencode.so`，所以目标 Linux 机器仍需安装对应架构的 `libqrencode` 运行库。

## 项目结构

```text
.
├── .github/
│   └── workflows/
│       └── build.yml
├── Makefile
├── README.md
└── main.c
```

## 注意事项

- 如果运行时报错 `libqrencode is required at runtime`，请先安装系统 `libqrencode` 运行库。
- 本项目的二进制名称已从 `qrencode-go` 改为 `qrencode`。
