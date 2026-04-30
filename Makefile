CC ?= cc
PKG_CONFIG ?= pkg-config
TARGET ?= qrencode
CFLAGS ?= -O2 -pipe -std=c17 -Wall -Wextra -Werror
LDFLAGS ?=
STATIC ?= 0

SRC := main.c render.c
OBJ := $(SRC:.c=.o)

ifeq ($(STATIC),1)
LDFLAGS += -static
PKG_CONFIG_LIBS = $(shell $(PKG_CONFIG) --static --libs libqrencode)
else
PKG_CONFIG_LIBS = $(shell $(PKG_CONFIG) --libs libqrencode)
endif

PKG_CONFIG_CFLAGS = $(shell $(PKG_CONFIG) --cflags libqrencode)

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $@ $(LDFLAGS) $(PKG_CONFIG_LIBS)

%.o: %.c render.h
	$(CC) $(CFLAGS) $(PKG_CONFIG_CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all clean