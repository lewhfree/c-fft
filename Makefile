export KFVER_MAJOR = 131
export KFVER_MINOR = 1
export KFVER_PATCH = 0
CC = zig cc -Wall -Wextra -Wpedantic
#
# Default options
#

export KISSFFT_STATIC ?= 0

#
# Installation directories
#

PREFIX ?= /usr/local
export ABS_PREFIX = $(abspath $(PREFIX))

BINDIR ?= $(ABS_PREFIX)/bin
export ABS_BINDIR = $(abspath $(BINDIR))

INCLUDEDIR ?= $(ABS_PREFIX)/include
export ABS_INCLUDEDIR = $(abspath $(INCLUDEDIR))
export ABS_PKGINCLUDEDIR = $(ABS_INCLUDEDIR)/kissfft

export INSTALL ?= install

KISSFFTLIB_SHORTNAME = kissfft-float
TYPEFLAGS =
PKGCONFIG_OPENMP =

ifeq ($(KISSFFT_STATIC), 1)
	KISSFFTLIB_NAME = lib$(KISSFFTLIB_SHORTNAME).a
	KISSFFTLIB_FLAGS += -static
else ifeq ($(shell uname -s),Darwin)
	KISSFFTLIB_NAME = lib$(KISSFFTLIB_SHORTNAME).dylib
	KISSFFTLIB_FLAGS += -shared -Wl,-install_name,$(KISSFFTLIB_NAME)
else
	KISSFFTLIB_SODEVELNAME = lib$(KISSFFTLIB_SHORTNAME).so
	KISSFFTLIB_SONAME = $(KISSFFTLIB_SODEVELNAME).$(KFVER_MAJOR)
	KISSFFTLIB_NAME = $(KISSFFTLIB_SONAME).$(KFVER_MINOR).$(KFVER_PATCH)
	KISSFFTLIB_FLAGS += -shared -Wl,-soname,$(KISSFFTLIB_SONAME)
endif

export KISSFFTLIB_SHORTNAME
export HAVE_LSX
export HAVE_LASX

TYPEFLAGS += -Dkiss_fft_scalar=float

ifneq ($(KISSFFT_STATIC), 1)
	TYPEFLAGS += -DKISS_FFT_SHARED
endif

TYPEFLAGS += -DKISS_FFT_BUILD

export TYPEFLAGS

%.c.o: %.c
	$(CC) -fPIC \
		-o $@ \
		$(CFLAGS) $(TYPEFLAGS) -DKISS_FFT_BUILD \
		-c $<

all: kfc.c.o kiss_fft.c.o kiss_fftnd.c.o kiss_fftndr.c.o kiss_fftr.c.o
ifneq ($(KISSFFT_STATIC), 1)
	$(CC) $(KISSFFTLIB_FLAGS) -o $(KISSFFTLIB_NAME) $^
  ifneq ($(shell uname -s),Darwin)
	ln -sf $(KISSFFTLIB_NAME) $(KISSFFTLIB_SONAME)
	ln -sf $(KISSFFTLIB_NAME) $(KISSFFTLIB_SODEVELNAME)
  endif
else
	$(AR) crus $(KISSFFTLIB_NAME) $^
endif

clean:
	rm -f *.o *.a *.so *.so.*
	rm -f kiss_fft*.tar.gz *~ *.pyc kiss_fft*.zip
