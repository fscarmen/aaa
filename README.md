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
- ⚡ 通过静态链接策略尽量减少运行时依赖
- 🌍 GitHub Actions 提供 Linux 多架构交叉编译产物

---

## 📦 依赖说明

运行源码构建需要：

- C17 编译器
- `make`
- `pkg-config`
- `libqrencode`

如果要静态链接构建，还需要安装 `libqrencode` 的静态库和对应开发文件。

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

仓库内的 [`release.yml`](.github/workflows/release.yml) 会在 Linux 多架构 Alpine 容器中：

1. 从源码构建 `libqrencode` 静态库
2. 使用 [`Makefile`](Makefile) 执行静态链接编译
3. 上传并发布以下产物：

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

说明：

- 工作流聚焦 Linux，不再包含 Go、多平台或非 C 相关流程。
- 为减少运行时依赖，工作流优先使用静态链接。

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
