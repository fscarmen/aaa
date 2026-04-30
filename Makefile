CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra -std=c99
LDFLAGS ?= -ldl
TARGET = qrencode

.PHONY: all clean

all: $(TARGET)

$(TARGET): main.c
	$(CC) $(CFLAGS) -o $@ main.c $(LDFLAGS)

clean:
	rm -f $(TARGET) qrencode-*
