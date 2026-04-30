# qrencode

👉 English version: [README_en.md](README_en.md)

---

## 📖 目录

- [项目介绍](#项目介绍)
- [功能特性](#功能特性)
- [依赖说明](#依赖说明)
- [构建方法](#构建方法)
- [使用方法](#使用方法)
- [GitHub Actions 交叉编译](#github-actions-交叉编译)
- [项目结构](#项目结构)

---

## 📌 项目介绍

`qrencode` 是一个极简的 C 命令行工具，用于在终端直接生成 ASCII 二维码。

适用于：

- 无图形界面的服务器（SSH）
- DevOps / 运维场景
- 快速分享链接（扫码访问）

---

## ✨ 功能特性

- 🧾 支持 URL / 任意文本
- 🖥️ 终端直接显示二维码
- 📏 半高压缩输出
- 🎨 二维码本体黑白反转显示
- 🔲 可控静区边框
- ⚡ 以真正静态链接为目标，避免运行时加载器缺失导致无法执行
- 🌍 GitHub Actions 提供 Linux / macOS / Windows 多架构构建产物

---

## 📦 依赖说明

运行源码构建需要：

- C17 编译器
- `make`
- `pkg-config`
- `libqrencode`

如果要静态链接构建，还需要安装 `libqrencode` 的静态库和对应开发文件。

如果二进制下载后执行时报错 `No such file or directory`，通常不是文件不存在，而是 ELF 解释器或动态加载器缺失。当前工作流已改为强制产出无动态解释器的静态二进制，以避免这个问题。

---

## 🛠️ 构建方法

### 动态链接构建

```bash
make
```

默认输出文件名：

```bash
./qrencode
```

### 静态链接构建

```bash
make STATIC=1
```

### 自定义输出名称

```bash
make TARGET=qrencode-linux-amd64
```

---

## ⚙️ 使用方法

```bash
qrencode [options] <text>
```

### 参数说明

| 参数       | 说明                              |
| ---------- | --------------------------------- |
| `-level`   | 纠错等级：L / M / Q / H（默认 L） |
| `-qz`      | 静区边框大小（默认 1）            |
| `-compact` | 半高压缩输出（默认 true）         |

### 示例

```bash
./qrencode -level L -qz 1 "https://example.com"
```

---

## 🧱 GitHub Actions 交叉编译

仓库内的 [`release.yml`](.github/workflows/release.yml) 会构建以下平台产物：

### Linux

- 基于 Alpine 多架构容器
- 从源码构建静态 `libqrencode`
- 强制检查产物不能带 ELF interpreter

```text
qrencode-linux-amd64
qrencode-linux-386
qrencode-linux-arm64
qrencode-linux-armv7
qrencode-linux-armv6
qrencode-linux-ppc64le
qrencode-linux-s390x
qrencode-linux-riscv64
```

### macOS

- 支持 Intel 和 Apple Silicon
- 从源码构建静态 `libqrencode`，减少额外三方库依赖

```text
qrencode-macos-amd64
qrencode-macos-arm64
```

### Windows

- 支持 x64 与 x86
- 使用 MSYS2 的 `MINGW64` / `MINGW32` 环境
- 以 `MSVCRT` 路线构建，目标兼容 Windows 7 及以上版本

```text
qrencode-windows-amd64.exe
qrencode-windows-386.exe
```

说明：

- 工作流只保留 C 版本相关构建流程。
- Linux 产物必须通过静态链接校验，否则工作流直接失败。
- Windows 构建显式使用 `-D_WIN32_WINNT=0x0601`，将最低目标版本固定为 Windows 7。

---

## 📁 项目结构

```text
qrencode/
├── main.c
├── render.c
├── render.h
├── Makefile
├── Product-Spec.md
├── README.md
├── README_en.md
└── .github/workflows/release.yml
```

---

## 📄 License

MIT
