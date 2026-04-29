# cfnat C multi-platform build files

Files in this package:

- `cfnat_windows.c`: Windows 7+ port. Uses Winsock2 and MinGW-w64 winpthread.
- `cfnat_macos.c`: macOS port for amd64 and arm64.
- `build-all.yml`: GitHub Actions workflow for Linux, Windows and macOS release artifacts.

Repository placement:

```text
cfnat.c
cfnat_windows.c
cfnat_macos.c
.github/workflows/build-all.yml
```

Windows build notes:

- Target: Windows 7 or newer via `_WIN32_WINNT=0x0601`.
- Compiler: MinGW-w64.
- Link libraries: `-lws2_32 -lwinpthread -static`.

macOS build notes:

- amd64 min target: macOS 10.13.
- arm64 min target: macOS 11.0, because Apple Silicon starts there.
- macOS does not support fully static libc binaries like Linux.
