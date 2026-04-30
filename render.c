#include "render.h"

#include <stdio.h>

static bool cell(const unsigned char *modules, int width, int x, int y, int quiet_zone, bool invert) {
  int gx = x - quiet_zone;
  int gy = y - quiet_zone;

  if (gx < 0 || gy < 0 || gx >= width || gy >= width) {
    return true;
  }

  bool value = modules[gy * width + gx] != 0;
  if (invert) {
    value = !value;
  }

  return value;
}


static void draw_compact(const unsigned char *modules, int width, int total_width, int total_height, int quiet_zone,
                         bool invert) {
  for (int y = 0; y < total_height; y += 2) {
    for (int x = 0; x < total_width; ++x) {
      bool top = cell(modules, width, x, y, quiet_zone, invert);
      bool bottom = false;
      if (y + 1 < total_height) {
        bottom = cell(modules, width, x, y + 1, quiet_zone, invert);
      }

      if (top && bottom) {
        fputs("█", stdout);
      } else if (top) {
        fputs("▀", stdout);
      } else if (bottom) {
        fputs("▄", stdout);
      } else {
        fputs(" ", stdout);
      }
    }
    fputc('\n', stdout);
  }
}


static void draw_full(const unsigned char *modules, int width, int total_width, int total_height, int quiet_zone,
                      bool invert) {
  for (int y = 0; y < total_height; ++y) {
    for (int x = 0; x < total_width; ++x) {
      if (cell(modules, width, x, y, quiet_zone, invert)) {
        fputs("██", stdout);
      } else {
        fputs("  ", stdout);
      }
    }
    fputc('\n', stdout);
  }
}


void draw_ascii_bitmap(const unsigned char *modules, int width, int quiet_zone, bool compact, bool invert) {
  if (modules == NULL || width <= 0 || quiet_zone < 0) {
    return;
  }

  int total_width = width + quiet_zone * 2;
  int total_height = width + quiet_zone * 2;

  if (compact) {
    draw_compact(modules, width, total_width, total_height, quiet_zone, invert);
  } else {
    draw_full(modules, width, total_width, total_height, quiet_zone, invert);
  }
}