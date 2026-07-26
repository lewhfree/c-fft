TARGET ?= x86_64-linux-gnu
CC = zig cc -target $(TARGET) -fPIC
AR = zig ar
SRC_DIR = src
BUILD_DIR = build
INCLUDE_DIR = include

CFLAGS = -Wall -Wextra -Wpedantic \
			-Wunused-function -Wunreachable-code \
			-fcolor-diagnostics -fdiagnostics-color=always \
			-O2 -g0 -I$(INCLUDE_DIR)/ \
			-DOUTSIDE_SPEEX -DEXPORT=__attribute__((visibility("default")))

TYPEFLAGS = -Dkiss_fft_scalar=float

KISSFFT_STATIC ?= 0

ifeq ($(KISSFFT_STATIC), 1)
	KISSFFTLIB_NAME = libkissfft-float.a
	KISSFFTLIB_FLAGS += -static
else
	KISSFFTLIB_NAME = libkissfft-float.so
	KISSFFTLIB_FLAGS += -shared -Wl,-soname,libkissfft-float.so
	TYPEFLAGS += -DKISS_FFT_SHARED
endif

$(BUILD_DIR)/%.c.o: $(SRC_DIR)/%.c
	$(CC) \
		-o $@ \
		$(CFLAGS) $(TYPEFLAGS) -DKISS_FFT_BUILD \
		-c $<

all: $(BUILD_DIR)/kiss_fft.c.o $(BUILD_DIR)/kiss_fftr.c.o $(BUILD_DIR)/real.c.o $(BUILD_DIR)/miniaudio.c.o $(BUILD_DIR)/resample.c.o
ifneq ($(KISSFFT_STATIC), 1)
	$(CC) $(KISSFFTLIB_FLAGS) -o $(KISSFFTLIB_NAME) $^
else
	$(AR) crus $(KISSFFTLIB_NAME) $^
endif

clean:
	rm -f $(BUILD_DIR)/*.o *.a *.so *.so.*
