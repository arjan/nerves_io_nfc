# Check that we're on a supported build platform
ifeq ($(CROSSCOMPILE),)
    # Not crosscompiling, so check that we're on Linux.
    ifneq ($(shell uname -s),Linux)
        $(error LibNFC driver only works on Linux. Crosscompiling is possible if $$CROSSCOMPILE is set.)
    endif
	BUILD := $(MAKE_HOST)
else
	BUILD := $(shell basename $(CROSSCOMPILE))
endif

TARGET := $(PWD)/target

include external.mk
include portdrv.mk

nfc_poller_sources = src/main.o

all: deps priv/nfc_poller

libnfc_url := "https://bintray.com/nfc-tools/sources/download_file?file_path=libnfc-1.7.1.tar.bz2"
libnfc_tar := libnfc-1.7.1.tar.bz2
libnfc_vsn := 1.7.1

libusb_url := "http://jaist.dl.sourceforge.net/project/libusb/libusb-0.1%20%28LEGACY%29/0.1.12/libusb-0.1.12.tar.gz"
libusb_tar := libusb-0.1.12.tar.gz
libusb_vsn := 0.1.12

deps: libusb libnfc

clean:
	rm -rf src/*.o priv/nfc_poller

distclean: clean
	rm -rf lib*gz lib*bz2 lib*-*


CFLAGS += -I$(TARGET)/include
LDFLAGS += -L$(TARGET)/lib

PORT_LDFLAGS += -L$(TARGET)/lib -lnfc -lusb -static
PORT_CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -I$(TARGET)/include
CC ?= $(CROSSCOMPILER)gcc

.PHONY: all clean

%.o: %.c
	$(CC) -c $(ERL_CFLAGS) $(PORT_CFLAGS) -o $@ $<

priv/nfc_poller: $(nfc_poller_sources)
	@mkdir -p priv
	$(CC) $^ $(ERL_LDFLAGS) $(PORT_LDFLAGS) -o $@
