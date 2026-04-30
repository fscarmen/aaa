# qrencode

👉 中文版本: [README.md](README.md)

---

## 📖 Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Dependencies](#dependencies)
- [Build](#build)
- [Usage](#usage)
- [GitHub Actions Cross Compilation](#github-actions-cross-compilation)
- [Project Structure](#project-structure)

---

## 📌 Introduction

`qrencode` is a minimal C CLI tool that generates ASCII QR codes directly in the terminal.

Ideal for:

- Headless servers (SSH)
- DevOps workflows
- Quickly sharing links via QR code

---

## ✨ Features

- 🧾 Supports URL and arbitrary text
- 🖥️ Terminal-friendly QR output
- 📏 Compact half-height rendering
- 🎨 Inverted QR body for improved visibility
- 🔲 Configurable quiet zone
- ⚡ Targets fully static binaries to avoid runtime loader related execution failures
- 🌍 Linux multi-architecture artifacts via GitHub Actions

---

## 📦 Dependencies

To build from source, you need:

- A C17 compiler
- `make`
- `pkg-config`
- `libqrencode`

For static builds, install the static `libqrencode` library and matching development files.

If a downloaded binary fails with `No such file or directory`, the file may exist but its ELF interpreter or dynamic loader is missing on the target host. The workflow now explicitly fails unless it produces a binary without a dynamic interpreter.

---

## 🛠️ Build

### Dynamic build

```bash
make
```

Default output file:

```bash
./qrencode
```

### Static build

```bash
make STATIC=1
```

### Custom output name

```bash
make TARGET=qrencode-linux-amd64
```

---

## ⚙️ Usage

```bash
qrencode [options] <text>
```

### Options

| Option     | Description                                 |
| ---------- | ------------------------------------------- |
| `-level`   | Error correction level (L/M/Q/H, default L) |
| `-qz`      | Quiet zone size (default 1)                 |
| `-compact` | Compact rendering (default true)            |

### Example

```bash
./qrencode -level L -qz 1 "https://example.com"
```

---

## 🧱 GitHub Actions Cross Compilation

The workflow in [`release.yml`](.github/workflows/release.yml) builds inside Linux multi-architecture Alpine containers and does the following:

1. Builds a static `libqrencode` from source
2. Uses [`Makefile`](Makefile) to build the CLI with static-link preference
3. Uploads and releases these artifacts:

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

Notes:

- The workflow is Linux-only and C-only.
- The workflow fails if the artifact still contains an ELF interpreter, preventing accidental dynamic release binaries.

---

## 📁 Project Structure

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
