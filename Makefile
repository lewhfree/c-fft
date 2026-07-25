export KFVER_MAJOR = 131
export KFVER_MINOR = 1
export KFVER_PATCH = 0

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

#
# Override LIBDIR with lib64 following CMake's
# GNUInstallDirs logic:
#

CANDIDATE_LIBDIR_NAME = lib

ifneq ($(MAKECMDGOALS),clean)
  ifeq ($(shell uname -s),Linux)
    _UNAME_ARCH = $(shell uname -i)

    ifeq (,$(_UNAME_ARCH))
	_UNAME_ARCH = $(shell uname -m)

      ifeq (,$(_UNAME_ARCH))
	$(warning WARNING: Can not detect system architecture!)
      endif
    endif

    ifeq ($(_UNAME_ARCH),x86_64)
	CANDIDATE_LIBDIR_NAME = lib64
    endif
    ifeq ($(_UNAME_ARCH),loongarch64)
        CANDIDATE_LIBDIR_NAME = lib64
    endif
  endif
endif

CANDIDATE_LIBDIR = $(PREFIX)/$(CANDIDATE_LIBDIR_NAME)
LIBDIR ?= $(CANDIDATE_LIBDIR)

export ABS_LIBDIR = $(abspath $(LIBDIR))

export INSTALL ?= install

#
# Library name and version
#

KISSFFTLIB_SHORTNAME = kissfft-float
KISSFFT_PKGCONFIG = kissfft-float.pc
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

#
# Compile-time definitions by datatype
#
#
# Note: -DKISS_FFT_BUILD and -DKISS_FFT_SHARED control
# C symbol visibility.
#

TYPEFLAGS += -Dkiss_fft_scalar=float

ifneq ($(KISSFFT_STATIC), 1)
	TYPEFLAGS += -DKISS_FFT_SHARED
endif

#
# Compile-time definitions
#

#
# Save pkgconfig variables before appending
# -DKISS_FFT_BUILD to TYPEFLAGS
#

ifneq ($(shell uname -s),Darwin)
	PKGCONFIG_KISSFFT_VERSION = $(KFVER_MAJOR).$(KFVER_MINOR).$(KFVER_PATCH)
	PKGCONFIG_KISSFFT_OUTPUT_NAME = $(KISSFFTLIB_SHORTNAME)
	PKGCONFIG_PKG_KISSFFT_DEFS = $(TYPEFLAGS)
	PKGCONFIG_KISSFFT_PREFIX = $(ABS_PREFIX)
  ifeq ($(ABS_INCLUDEDIR),$(ABS_PREFIX)/include)
	PKGCONFIG_KISSFFT_INCLUDEDIR = $${prefix}/include
  else
	PKGCONFIG_KISSFFT_INCLUDEDIR = $(ABS_INCLUDEDIR)

  endif
  ifeq ($(ABS_LIBDIR),$(ABS_PREFIX)/$(CANDIDATE_LIBDIR_NAME))
	PKGCONFIG_KISSFFT_LIBDIR = $${prefix}/$(CANDIDATE_LIBDIR_NAME)
  else
	PKGCONFIG_KISSFFT_LIBDIR = $(ABS_LIBDIR)
  endif
	PKGCONFIG_KISSFFT_PKGINCLUDEDIR = $${includedir}/kissfft
endif

export TYPEFLAGS

# Compile .c into .o
#

#
# -DKISS_FFT_BUILD is used for library artifacts, so
# consumer executable in 'test' and 'tools' do _NOT_
# need it. pkg-config output does not need it either.
#

%.c.o: %.c
	$(CC) -Wall -fPIC \
		-o $@ \
		$(CFLAGS) $(TYPEFLAGS) -DKISS_FFT_BUILD \
		-c $<

#
# Target: "make all"
#

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

#
# Target: "make install"
#

install: all
	$(INSTALL) -Dt $(ABS_PKGINCLUDEDIR) -m 644 \
		kiss_fft.h \
		kissfft.hh \
		kiss_fftnd.h \
		kiss_fftndr.h \
		kiss_fftr.h
	$(INSTALL) -Dt $(ABS_LIBDIR) -m 644 $(KISSFFTLIB_NAME)
ifneq ($(KISSFFT_STATIC), 1)
  ifneq ($(shell uname -s),Darwin)
	cd $(LIBDIR) && \
	ln -sf $(KISSFFTLIB_NAME) $(KISSFFTLIB_SONAME) && \
	ln -sf $(KISSFFTLIB_NAME) $(KISSFFTLIB_SODEVELNAME)
  endif
endif
ifneq ($(shell uname -s),Darwin)
	mkdir -p "$(ABS_LIBDIR)/pkgconfig"
	sed \
		-e 's+@PKGCONFIG_KISSFFT_VERSION@+$(PKGCONFIG_KISSFFT_VERSION)+' \
		-e 's+@KISSFFT_OUTPUT_NAME@+$(PKGCONFIG_KISSFFT_OUTPUT_NAME)+' \
		-e 's+@PKG_KISSFFT_DEFS@+$(PKGCONFIG_PKG_KISSFFT_DEFS)+' \
		-e 's+@PKG_OPENMP@+$(PKGCONFIG_OPENMP)+' \
		-e 's+@PKGCONFIG_KISSFFT_PREFIX@+$(PKGCONFIG_KISSFFT_PREFIX)+' \
		-e 's+@PKGCONFIG_KISSFFT_INCLUDEDIR@+$(PKGCONFIG_KISSFFT_INCLUDEDIR)+' \
		-e 's+@PKGCONFIG_KISSFFT_LIBDIR@+$(PKGCONFIG_KISSFFT_LIBDIR)+' \
		-e 's+@PKGCONFIG_KISSFFT_PKGINCLUDEDIR@+$(PKGCONFIG_KISSFFT_PKGINCLUDEDIR)+' \
		kissfft.pc.in 1>"$(ABS_LIBDIR)/pkgconfig/$(KISSFFT_PKGCONFIG)"
endif

#
# Target: "make clean"
#

clean:
	rm -f *.o *.a *.so *.so.*
	rm -f kiss_fft*.tar.gz *~ *.pyc kiss_fft*.zip
