CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
LDFLAGS ?= -pthread
TARGET ?= cfnat

all:
	$(CC) $(CFLAGS) -o $(TARGET) cfnat.c $(LDFLAGS)

strip:
	strip $(TARGET) || true

clean:
	rm -f cfnat cfnat-*
