# Author: Peter Dobler (@Juppit)
#
# Last edited: 05.12.2018

BUILDPATH = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"$(PATH)"

PLATFORM := $(shell uname -s)
ifneq (,$(findstring 64, $(shell uname -m)))
    ARCH := 64
else
    ARCH := 32
endif

BUILD_OS := $(PLATFORM)
ifeq ($(OS),Windows_NT)
    ifneq (,$(findstring MINGW32,$(PLATFORM)))
        BUILD_OS := Mingw$(ARCH)
        BUILDPATH := /mingw$(ARCH)/bin:$(BUILDPATH)
    endif
    ifneq (,$(findstring MINGW64,$(PLATFORM)))
        BUILD_OS := Mingw$(ARCH)
        BUILDPATH := /mingw$(ARCH)/bin:$(BUILDPATH)
    endif
    ifneq (,$(findstring MSYS,$(PLATFORM)))
        #BUILD_OS := MSYS$(ARCH)
        BUILD_OS := Msys$(ARCH)
        #BUILDPATH := /msys$(ARCH)/usr/bin:$(BUILDPATH)
        BUILDPATH := /bin:/usr/bin:/c/ProgramData/chocolatey/bin:/c/ProgramData/chocolatey/lib/mingw/tools/install/mingw64/bin
    endif
endif

all:
	@echo "Platform:  $(PLATFORM)"
	@echo "Build ist: $(BUILD_OS)"
	@echo "SysPath:   $(PATH)"
	@echo "BuildPath: $(BUILDPATH)"
	where sh.exe
	wget https://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.bz2
	bsdtar -xf gmp-6.1.2.tar.bz2
	mkdir -p build-gmp
	mkdir -p libs
	PATH=$(BUILDPATH); cd build-gmp; ../gmp-6.1.2/configure --prefix=$(PWD)/libs/gmp-6.1.2 --host=x86_64-pc-mingw32  --disable-shared --enable-static
	PATH=$(BUILDPATH); $(MAKE) -C build-gmp
	PATH=$(BUILDPATH); $(MAKE) install -s -C build-gmp
