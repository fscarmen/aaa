#include <qrencode.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "render.h"

static void usage(void) {
  fprintf(stderr, "USAGE: qrencode-go [options] <url>\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "OPTIONS:\n");
  fprintf(stderr, "  -level L/M/Q/H   Error correction level (default L)\n");
  fprintf(stderr, "  -qz int          Quiet zone size (default 1)\n");
  fprintf(stderr, "  -compact         Half-height rendering (default true)\n");
}


static QRecLevel parse_level(const char *value) {
  if (value == NULL || *value == '\0') {
    fprintf(stderr, "Error: invalid level \"\"\n");
    exit(1);
  }

  if (strcasecmp(value, "L") == 0) {
    return QR_ECLEVEL_L;
  }
  if (strcasecmp(value, "M") == 0) {
    return QR_ECLEVEL_M;
  }
  if (strcasecmp(value, "Q") == 0) {
    return QR_ECLEVEL_Q;
  }
  if (strcasecmp(value, "H") == 0) {
    return QR_ECLEVEL_H;
  }

  fprintf(stderr, "Error: invalid level \"%s\"\n", value);
  exit(1);
}


static bool parse_bool_value(const char *value) {
  if (value == NULL) {
    return true;
  }

  if (strcasecmp(value, "true") == 0 || strcmp(value, "1") == 0) {
    return true;
  }
  if (strcasecmp(value, "false") == 0 || strcmp(value, "0") == 0) {
    return false;
  }

  fprintf(stderr, "Error: invalid boolean value \"%s\" for -compact\n", value);
  exit(1);
}


static int parse_int_value(const char *value, const char *flag_name) {
  char *end = NULL;
  long parsed;

  if (value == NULL || *value == '\0') {
    fprintf(stderr, "Error: invalid integer value \"\" for %s\n", flag_name);
    exit(1);
  }

  parsed = strtol(value, &end, 10);
  if (end == NULL || *end != '\0') {
    fprintf(stderr, "Error: invalid integer value \"%s\" for %s\n", value, flag_name);
    exit(1);
  }

  if (parsed < 0 || parsed > 1024) {
    fprintf(stderr, "Error: integer value out of range \"%s\" for %s\n", value, flag_name);
    exit(1);
  }

  return (int) parsed;
}


static char *trimmed_copy(const char *value) {
  const char *start = value;
  size_t length;
  char *copy;

  while (*start == ' ' || *start == '\t' || *start == '\n' || *start == '\r') {
    ++start;
  }

  length = strlen(start);
  while (length > 0) {
    char tail = start[length - 1];
    if (tail == ' ' || tail == '\t' || tail == '\n' || tail == '\r') {
      --length;
    } else {
      break;
    }
  }

  if (length == 0) {
    return NULL;
  }

  copy = (char *) malloc(length + 1);
  if (copy == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    exit(1);
  }

  memcpy(copy, start, length);
  copy[length] = '\0';
  return copy;
}


int main(int argc, char **argv) {
  const char *level = "L";
  int quiet_zone = 1;
  bool compact = true;
  const char *content = NULL;

  for (int i = 1; i < argc; ++i) {
    const char *arg = argv[i];

    if (strcmp(arg, "-level") == 0) {
      if (i + 1 >= argc) {
        usage();
        return 1;
      }
      level = argv[++i];
      continue;
    }

    if (strncmp(arg, "-level=", 7) == 0) {
      level = arg + 7;
      continue;
    }

    if (strcmp(arg, "-qz") == 0) {
      if (i + 1 >= argc) {
        usage();
        return 1;
      }
      quiet_zone = parse_int_value(argv[++i], "-qz");
      continue;
    }

    if (strncmp(arg, "-qz=", 4) == 0) {
      quiet_zone = parse_int_value(arg + 4, "-qz");
      continue;
    }

    if (strcmp(arg, "-compact") == 0) {
      compact = true;
      continue;
    }

    if (strncmp(arg, "-compact=", 9) == 0) {
      compact = parse_bool_value(arg + 9);
      continue;
    }

    if (arg[0] == '-') {
      usage();
      return 1;
    }

    if (content != NULL) {
      usage();
      return 1;
    }

    content = arg;
  }

  if (content == NULL) {
    usage();
    return 1;
  }

  char *trimmed = trimmed_copy(content);
  if (trimmed == NULL) {
    usage();
    return 1;
  }

  QRecLevel qr_level = parse_level(level);
  QRcode *qr = QRcode_encodeString8bit(trimmed, 0, qr_level);
  free(trimmed);

  if (qr == NULL) {
    fprintf(stderr, "Error: failed to generate QR code\n");
    return 1;
  }

  int width = qr->width;
  unsigned char *modules = (unsigned char *) malloc((size_t) width * (size_t) width);
  if (modules == NULL) {
    fprintf(stderr, "Error: out of memory\n");
    QRcode_free(qr);
    return 1;
  }

  for (int y = 0; y < width; ++y) {
    for (int x = 0; x < width; ++x) {
      modules[y * width + x] = (unsigned char) ((qr->data[y * width + x] & 0x1) != 0 ? 1 : 0);
    }
  }

  draw_ascii_bitmap(modules, width, quiet_zone, compact, true);

  free(modules);
  QRcode_free(qr);
  return 0;
}