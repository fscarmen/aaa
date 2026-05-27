APP := better-cf-ip-c
SRC := better_cf_ip.c
CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra -Wno-unused-parameter -pedantic
PKG_CFLAGS := $(shell pkg-config --cflags libcurl openssl 2>/dev/null)
PKG_LIBS := $(shell pkg-config --libs libcurl openssl 2>/dev/null)
ifeq ($(strip $(PKG_LIBS)),)
PKG_LIBS := -lcurl -lssl -lcrypto
endif

.PHONY: all clean dist linux-amd64

all: $(APP)

$(APP): $(SRC)
	$(CC) $(CFLAGS) $(PKG_CFLAGS) -o $@ $< $(PKG_LIBS) -pthread

linux-amd64: dist
	$(CC) $(CFLAGS) $(PKG_CFLAGS) -o dist/$(APP)-linux-amd64 $(SRC) $(PKG_LIBS) -pthread
	chmod +x dist/$(APP)-linux-amd64

dist:
	mkdir -p dist

clean:
	rm -f $(APP)
	rm -rf dist
