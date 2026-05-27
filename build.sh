#!/usr/bin/env bash
set -euo pipefail

APP_NAME="better-cf-ip-c"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
SOURCE_FILE="$ROOT_DIR/better_cf_ip.c"

TARGETS=(
  "linux-amd64"
  "macos-amd64"
  "macos-arm64"
  "windows-amd64"
  "windows-386"
)

print_targets() {
  echo "可选编译目标：" >&2
  local i=1
  for target in "${TARGETS[@]}"; do
    printf '  %d) %s\n' "$i" "$target" >&2
    i=$((i + 1))
  done
  echo "  a) all-supported" >&2
  echo "  q) quit" >&2
}

select_target() {
  local input="${1:-}"
  if [ -z "$input" ]; then
    print_targets
    printf '请选择目标，默认 linux-amd64: ' >&2
    read -r input || true
  fi
  case "${input:-linux-amd64}" in
    1|linux-amd64) echo "linux-amd64" ;;
    2|macos-amd64) echo "macos-amd64" ;;
    3|macos-arm64) echo "macos-arm64" ;;
    4|windows-amd64) echo "windows-amd64" ;;
    5|windows-386) echo "windows-386" ;;
    a|all|all-supported) echo "all-supported" ;;
    q|quit|exit) exit 0 ;;
    *) echo "未知目标: $input" >&2; exit 2 ;;
  esac
}

pkg_flags() {
  pkg-config --cflags --libs libcurl openssl 2>/dev/null || printf '%s\n' '-lcurl -lssl -lcrypto'
}

build_linux_amd64() {
  mkdir -p "$DIST_DIR"
  cc -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
    "$SOURCE_FILE" -o "$DIST_DIR/$APP_NAME-linux-amd64" \
    $(pkg_flags) -pthread
  chmod +x "$DIST_DIR/$APP_NAME-linux-amd64"
}

build_macos() {
  local arch="$1"
  local suffix="amd64"
  local minver="10.13"
  if [ "$arch" = "arm64" ]; then
    suffix="arm64"
    minver="11.0"
  fi
  mkdir -p "$DIST_DIR"
  clang -O2 -pipe -std=c11 -Wall -Wextra -Wno-unused-parameter \
    -arch "$arch" -mmacosx-version-min="$minver" \
    "$SOURCE_FILE" -o "$DIST_DIR/$APP_NAME-macos-$suffix" \
    $(pkg-config --cflags --libs libcurl openssl) -pthread
  strip "$DIST_DIR/$APP_NAME-macos-$suffix" 2>/dev/null || true
  chmod +x "$DIST_DIR/$APP_NAME-macos-$suffix"
}

build_windows() {
  local arch="$1"
  local cc_bin="x86_64-w64-mingw32-gcc"
  local out="$DIST_DIR/$APP_NAME-windows-amd64.exe"
  if [ "$arch" = "386" ]; then
    cc_bin="i686-w64-mingw32-gcc"
    out="$DIST_DIR/$APP_NAME-windows-386.exe"
  fi
  command -v "$cc_bin" >/dev/null 2>&1 || {
    echo "缺少 $cc_bin。请在 MSYS2/MinGW-w64 环境编译，或使用 GitHub Actions。" >&2
    exit 3
  }
  mkdir -p "$DIST_DIR"
  "$cc_bin" -O2 -pipe -std=c11 -DWINVER=0x0601 -D_WIN32_WINNT=0x0601 \
    -finput-charset=UTF-8 -fexec-charset=UTF-8 \
    -Wall -Wextra -Wno-unused-parameter \
    "$SOURCE_FILE" -o "$out" \
    $(pkg-config --cflags --libs libcurl openssl 2>/dev/null || true) \
    -lws2_32 -lcrypt32 -lbcrypt -lwinpthread -static -s
}

build_one() {
  case "$1" in
    linux-amd64) build_linux_amd64 ;;
    macos-amd64) build_macos x86_64 ;;
    macos-arm64) build_macos arm64 ;;
    windows-amd64) build_windows amd64 ;;
    windows-386) build_windows 386 ;;
    *) echo "未知目标: $1" >&2; exit 2 ;;
  esac
}

target="$(select_target "${1:-}")"
if [ "$target" = "all-supported" ]; then
  for t in "${TARGETS[@]}"; do
    echo "==> build $t"
    build_one "$t"
  done
else
  build_one "$target"
fi

find "$DIST_DIR" -maxdepth 1 -type f -print
