#ifndef RENDER_H
#define RENDER_H

#include <stdbool.h>

void draw_ascii_bitmap(const unsigned char *modules, int width, int quiet_zone, bool compact, bool invert);

#endif