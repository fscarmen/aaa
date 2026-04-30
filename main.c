#include <ctype.h>
#ifndef USE_STATIC_QRENCODE
#include <dlfcn.h>
#endif
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

typedef enum {
    QR_ECLEVEL_L = 0,
    QR_ECLEVEL_M,
    QR_ECLEVEL_Q,
    QR_ECLEVEL_H
} QRecLevel;

typedef struct {
    int version;
    int width;
    unsigned char *data;
} QRcode;

#ifdef USE_STATIC_QRENCODE
extern QRcode *QRcode_encodeString(const char *string, int version, QRecLevel level, int hint, int casesensitive);
extern void QRcode_free(QRcode *qrcode);
#else
typedef QRcode *(*QRcode_encodeString_fn)(const char *, int, QRecLevel, int, int);
typedef void (*QRcode_free_fn)(QRcode *);

typedef struct {
    QRcode_encodeString_fn encodeString;
    QRcode_free_fn freeCode;
    void *handle;
} QRLib;
#endif

static void usage(void) {
    fprintf(stderr, "USAGE: qrencode [options] <url>\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "OPTIONS:\n");
    fprintf(stderr, "  -level L/M/Q/H   Error correction level (default L)\n");
    fprintf(stderr, "  -qz int          Quiet zone size (default 1)\n");
    fprintf(stderr, "  -compact         Half-height rendering (default true)\n");
}

static char *trim_copy(const char *s) {
    const unsigned char *start = (const unsigned char *)s;
    while (*start && isspace(*start)) start++;
    const unsigned char *end = start + strlen((const char *)start);
    while (end > start && isspace(*(end - 1))) end--;
    size_t len = (size_t)(end - start);
    char *out = (char *)malloc(len + 1);
    if (!out) return NULL;
    memcpy(out, start, len);
    out[len] = '\0';
    return out;
}

static bool parse_level(const char *s, QRecLevel *level) {
    if (!s) return false;
    while (*s && isspace((unsigned char)*s)) s++;
    char c = (char)toupper((unsigned char)*s);
    s++;
    while (*s && isspace((unsigned char)*s)) s++;
    if (*s != '\0') return false;
    switch (c) {
        case 'L': *level = QR_ECLEVEL_L; return true;
        case 'M': *level = QR_ECLEVEL_M; return true;
        case 'Q': *level = QR_ECLEVEL_Q; return true;
        case 'H': *level = QR_ECLEVEL_H; return true;
        default: return false;
    }
}

static bool parse_bool(const char *s, bool *value) {
    if (!s) return false;
    if (strcasecmp(s, "true") == 0 || strcasecmp(s, "t") == 0 || strcmp(s, "1") == 0) {
        *value = true;
        return true;
    }
    if (strcasecmp(s, "false") == 0 || strcasecmp(s, "f") == 0 || strcmp(s, "0") == 0) {
        *value = false;
        return true;
    }
    return false;
}

static bool parse_int(const char *s, int *value) {
    char *end = NULL;
    errno = 0;
    long v = strtol(s, &end, 10);
    if (errno != 0 || end == s || *end != '\0' || v < 0 || v > 100000) return false;
    *value = (int)v;
    return true;
}

#ifndef USE_STATIC_QRENCODE
static bool load_qr_library(QRLib *lib) {
    const char *names[] = {"libqrencode.so.4", "libqrencode.so", NULL};
    memset(lib, 0, sizeof(*lib));
    for (int i = 0; names[i]; i++) {
        lib->handle = dlopen(names[i], RTLD_LAZY);
        if (lib->handle) break;
    }
    if (!lib->handle) {
        fprintf(stderr, "Error: libqrencode is required at runtime. Install libqrencode or use a static release binary.\n");
        return false;
    }
    lib->encodeString = (QRcode_encodeString_fn)dlsym(lib->handle, "QRcode_encodeString");
    lib->freeCode = (QRcode_free_fn)dlsym(lib->handle, "QRcode_free");
    if (!lib->encodeString || !lib->freeCode) {
        fprintf(stderr, "Error: libqrencode does not expose the required API.\n");
        dlclose(lib->handle);
        memset(lib, 0, sizeof(*lib));
        return false;
    }
    return true;
}
#endif

static bool cell(const unsigned char *matrix, int width, int x, int y, int qz, bool invert) {
    int gx = x - qz;
    int gy = y - qz;
    bool in_qr = gx >= 0 && gy >= 0 && gy < width && gx < width;
    if (!in_qr) return true;
    bool v = (matrix[gy * width + gx] & 0x01) != 0;
    return invert ? !v : v;
}

static void draw_compact(const unsigned char *matrix, int total_w, int total_h, int width, int qz, bool invert) {
    for (int y = 0; y < total_h; y += 2) {
        for (int x = 0; x < total_w; x++) {
            bool top = cell(matrix, width, x, y, qz, invert);
            bool bottom = false;
            if (y + 1 < total_h) bottom = cell(matrix, width, x, y + 1, qz, invert);
            if (top && bottom) fputs("█", stdout);
            else if (top && !bottom) fputs("▀", stdout);
            else if (!top && bottom) fputs("▄", stdout);
            else fputc(' ', stdout);
        }
        fputc('\n', stdout);
    }
}

static void draw_full(const unsigned char *matrix, int total_w, int total_h, int width, int qz, bool invert) {
    for (int y = 0; y < total_h; y++) {
        for (int x = 0; x < total_w; x++) {
            if (cell(matrix, width, x, y, qz, invert)) fputs("██", stdout);
            else fputs("  ", stdout);
        }
        fputc('\n', stdout);
    }
}

static void draw_ascii_bitmap(const unsigned char *matrix, int width, int quiet_zone, bool compact, bool invert) {
    if (!matrix || width <= 0) return;
    int total_w = width + quiet_zone * 2;
    int total_h = width + quiet_zone * 2;
    if (compact) draw_compact(matrix, total_w, total_h, width, quiet_zone, invert);
    else draw_full(matrix, total_w, total_h, width, quiet_zone, invert);
}

int main(int argc, char **argv) {
    const char *level_text = "L";
    int quiet_zone = 1;
    bool compact = true;
    const char *arg_content = NULL;

    for (int i = 1; i < argc; i++) {
        char *arg = argv[i];
        if (strcmp(arg, "-level") == 0) {
            if (++i >= argc) { usage(); return 1; }
            level_text = argv[i];
        } else if (strncmp(arg, "-level=", 7) == 0) {
            level_text = arg + 7;
        } else if (strcmp(arg, "-qz") == 0) {
            if (++i >= argc || !parse_int(argv[i], &quiet_zone)) { usage(); return 1; }
        } else if (strncmp(arg, "-qz=", 4) == 0) {
            if (!parse_int(arg + 4, &quiet_zone)) { usage(); return 1; }
        } else if (strcmp(arg, "-compact") == 0) {
            compact = true;
        } else if (strncmp(arg, "-compact=", 9) == 0) {
            if (!parse_bool(arg + 9, &compact)) { usage(); return 1; }
        } else if (arg[0] == '-') {
            usage();
            return 1;
        } else if (!arg_content) {
            arg_content = arg;
        } else {
            usage();
            return 1;
        }
    }

    if (!arg_content) { usage(); return 1; }

    char *content = trim_copy(arg_content);
    if (!content || content[0] == '\0') {
        free(content);
        usage();
        return 1;
    }

    QRecLevel level;
    if (!parse_level(level_text, &level)) {
        fprintf(stderr, "Error: invalid level %s\n", level_text);
        free(content);
        return 1;
    }

#ifdef USE_STATIC_QRENCODE
    QRcode *qr = QRcode_encodeString(content, 0, level, 2, 1);
    if (!qr) {
        fprintf(stderr, "Error: failed to encode QR code\n");
        free(content);
        return 1;
    }
    draw_ascii_bitmap(qr->data, qr->width, quiet_zone, compact, true);
    QRcode_free(qr);
#else
    QRLib lib;
    if (!load_qr_library(&lib)) {
        free(content);
        return 1;
    }
    QRcode *qr = lib.encodeString(content, 0, level, 2, 1);
    if (!qr) {
        fprintf(stderr, "Error: failed to encode QR code\n");
        dlclose(lib.handle);
        free(content);
        return 1;
    }
    draw_ascii_bitmap(qr->data, qr->width, quiet_zone, compact, true);
    lib.freeCode(qr);
    dlclose(lib.handle);
#endif
    free(content);
    return 0;
}
