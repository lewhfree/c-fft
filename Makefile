TARGET ?= x86_64-linux-gnu
CC = zig cc -target $(TARGET) -fPIC
AR = zig ar
# CC = clang
# AR = ar
SRC_DIR = src
BUILD_DIR = build
INCLUDE_DIR = include

CFLAGS = -Wall -Wextra -Wpedantic \
			-Wunused-function -Wunreachable-code \
			-fcolor-diagnostics -fdiagnostics-color=always \
			-O2 -g0 -I$(INCLUDE_DIR)/ \
			-DOUTSIDE_SPEEX -DEXPORT=__attribute__\(\(visibility\(\"default\"\)\)\) \
			-DFLOATING_POINT -DRANDOM_PREFIX=libretune \
			-DDRFLAC_API=__attribute__\(\(visibility\(\"default\"\)\)\) \
			-DDRWAV_API=__attribute__\(\(visibility\(\"default\"\)\)\) \
			-DDRMP3_API=__attribute__\(\(visibility\(\"default\"\)\)\) \
			-DDRWAV_PRIVATE=static \
			-DDR_MP3_NO_STDIO -DDR_MP3_NO_SIMD \
			-DDR_WAV_NO_STDIO -DDR_WAV_NO_SIMD \
			-DDR_FLAC_NO_STDIO -DDR_FLAC_NO_SIMD \
			-DXXH_NO_STDLIB -DXXH_NO_XXH3

KISSFFT_STATIC ?= 0

ifeq ($(KISSFFT_STATIC), 1)
	KISSFFTLIB_NAME = libkissfft-float.a
	KISSFFTLIB_FLAGS += -static
else
	KISSFFTLIB_NAME = libkissfft-float.so
	KISSFFTLIB_FLAGS += -shared -Wl,-soname,libkissfft-float.so
	CFLAGS += -DKISS_FFT_SHARED
endif

$(BUILD_DIR)/%.c.o: $(SRC_DIR)/%.c
	mkdir -p $(BUILD_DIR)
	$(CC) \
		-o $@ \
		$(CFLAGS) $(TYPEFLAGS) -DKISS_FFT_BUILD \
		-c $<

all: $(BUILD_DIR)/kiss_fft.c.o $(BUILD_DIR)/kiss_fftr.c.o $(BUILD_DIR)/real.c.o $(BUILD_DIR)/dr_flac.c.o $(BUILD_DIR)/dr_mp3.c.o $(BUILD_DIR)/dr_wav.c.o $(BUILD_DIR)/resample.c.o $(BUILD_DIR)/decode.c.o
ifneq ($(KISSFFT_STATIC), 1)
	$(CC) $(KISSFFTLIB_FLAGS) -o $(KISSFFTLIB_NAME) $^
else
	$(AR) crus $(KISSFFTLIB_NAME) $^
endif

clean:
	rm -rf $(BUILD_DIR) *.a *.so *.so.*
