KFVER_MAJOR = 131
KFVER_MINOR = 1
KFVER_PATCH = 0

TARGET ?= x86_64-linux-gnu
CC = zig cc -target $(TARGET) -fPIC
AR = zig ar

CFLAGS = -Wall -Wextra -Wpedantic \
			-fcolor-diagnostics -fdiagnostics-color=always \
			-O3 -g0 \
			-fsanitize=address,undefined

SRC_DIR = src/
BUILD_DIR = build/
INCLUDE_DIR = include/

CFLAGS += -I$(INCLUDE_DIR)

KISSFFT_STATIC ?= 0

ifeq ($(KISSFFT_STATIC), 1)
	KISSFFTLIB_NAME = libkissfft-float.a
	KISSFFTLIB_FLAGS += -static
else
	KISSFFTLIB_NAME = libkissfft-float.so.$(KFVER_MAJOR).$(KFVER_MINOR).$(KFVER_PATCH)
	KISSFFTLIB_FLAGS += -shared -Wl,-soname,libkissfft-float.so.$(KFVER_MAJOR)
endif

TYPEFLAGS = -Dkiss_fft_scalar=float

ifneq ($(KISSFFT_STATIC), 1)
	TYPEFLAGS += -DKISS_FFT_SHARED
endif

$(BUILD_DIR)%.c.o: $(SRC_DIR)%.c
	$(CC) \
		-o $@ \
		$(CFLAGS) $(TYPEFLAGS) -DKISS_FFT_BUILD \
		-c $<

all: $(BUILD_DIR)kfc.c.o $(BUILD_DIR)kiss_fft.c.o $(BUILD_DIR)kiss_fftnd.c.o $(BUILD_DIR)kiss_fftndr.c.o $(BUILD_DIR)kiss_fftr.c.o
ifneq ($(KISSFFT_STATIC), 1)
	$(CC) $(KISSFFTLIB_FLAGS) -o $(KISSFFTLIB_NAME) $^
else
	$(AR) crus $(KISSFFTLIB_NAME) $^
endif

clean:
	rm -f $(BUILD_DIR)*.o *.a *.so *.so.*
