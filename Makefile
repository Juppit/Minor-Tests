# Author: Peter Dobler (@Juppit)
#
# Last edit: 21.06.2018

BUILDPATH = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:

PLATFORM := $(shell uname -s)
ifneq (,$(findstring 64, $(shell uname -m)))
    ARCH := 64
else
    ARCH := 32
endif

BUILD :=
CURSES_MINGW_BUILD :=

BUILD_OS := $(PLATFORM)
ifeq ($(OS),Windows_NT)
    ifneq (,$(findstring MINGW32,$(PLATFORM)))
        BUILD_OS := Mingw$(ARCH)
        BUILDPATH := /mingw$(ARCH)/bin:$(BUILDPATH)
        # on Mingw only for CURSES necessary
        BUILD :=
        CURSES_MINGW_BUILD := --build=x86_64-pc-mingw$(ARCH)
    endif
    ifneq (,$(findstring MINGW64,$(PLATFORM)))
        BUILD_OS := Mingw$(ARCH)
        BUILDPATH := /mingw$(ARCH)/bin:$(BUILDPATH)
        # on Mingw only for CURSES necessary
        BUILD :=
        CURSES_MINGW_BUILD := --build=x86_64-pc-mingw$(ARCH)
    endif
    ifneq (,$(findstring MSYS,$(PLATFORM)))
        BUILD_OS := MSYS$(ARCH)
        BUILDPATH := /msys$(ARCH)/usr/bin:$(BUILDPATH)
    endif
    ifneq (,$(findstring CYGWIN,$(PLATFORM)))
        BUILD_OS := Cygwin$(ARCH)
        # on Cygwin necessary for GMP and GDB
        BUILD := --build=x86_64-unknown-cygwin
    endif
    ifneq (,$(findstring Cygwin,$(PLATFORM)))
        BUILD_OS := Cygwin$(ARCH)
        # on Cygwin necessary for GMP and GDB
        BUILD := --build=x86_64-unknown-cygwin
    endif
else
    ifeq ($(PLATFORM),Darwin)
        BUILD_OS := MacOS$(ARCH)
    endif
    ifeq ($(PLATFORM),Linux)
        BUILD_OS := Linux$(ARCH)
        ifneq (,$(findstring ARM,$(PLATFORM)))
            BUILD_OS := LinuxARM$(ARCH)
        endif
        ifneq (,$(findstring AARCH64,$(PLATFORM)))
            BUILD_OS := LinuxARM$(ARCH)
        endif
    endif
endif

TARGET = xtensa-lx106-elf

# create tar-file for distribution
DISTRIB  = ""
DISTRIB  = $(BUILD_OS)-$(TARGET)
USE_DISTRIB = y

TOP = $(PWD)

TOOLCHAIN = $(TOP)/$(TARGET)
TARGET_DIR = $(TOOLCHAIN)/$(TARGET)

SAFEPATH = "$(TOOLCHAIN)/bin:"$(BUILDPATH)

COMP_LIB = $(TOP)/comp_libs
SOURCE_DIR = $(TOP)/src
TAR_DIR = $(TOP)/tarballs
PATCHES_DIR = $(SOURCE_DIR)/patches
BUILD_DIR = build-$(BUILD_OS)
DIST_DIR = $(TOP)/distrib

OUTPUT_DATE = date +"%Y-%m-%d %X" 

# Log file
BUILD_LOG = $(DIST_DIR)/$(BUILD_OS)-build.log
ERROR_LOG = $(DIST_DIR)/$(BUILD_OS)-error.log

GNU_URL = https://ftp.gnu.org/gnu

GMP_VERSION = 6.1.2
GCC_VERSION  = 8.1.0
GCC_VERSION  = xtensa

GMP = gmp
GMP_DIR = $(SOURCE_DIR)/$(GMP)-$(GMP_VERSION)
# make it easy for gmp-6.0.0a
ifneq (,$(findstring 6.0.0a,$(GMP_VERSION)))
    GMP_DIR = $(SOURCE_DIR)/$(GMP)-6.0.0
endif
BUILD_GMP_DIR = $(GMP_DIR)/$(BUILD_DIR)
GMP_URL = $(GNU_URL)/$(GMP)/$(GMP)-$(GMP_VERSION).tar.bz2
GMP_TAR = $(TAR_DIR)/$(GMP)-$(GMP_VERSION).tar.bz2
GMP_TAR_DIR = $(GMP)-$(GMP_VERSION)

GCC = gcc
GCC_DIR = $(SOURCE_DIR)/$(GCC)-$(GCC_VERSION)
BUILD_GCC_DIR = $(GCC_DIR)/$(BUILD_DIR)
GCC_URL = $(GNU_URL)/$(GCC)/$(GCC)-$(GCC_VERSION)/$(GCC)-$(GCC_VERSION).tar.gz
GCC_TAR = $(TAR_DIR)/$(GCC)-$(GCC_VERSION).tar.gz
GCC_TAR_DIR = $(GCC)-$(GCC_VERSION)
ifneq (,$(findstring xtensa,$(GCC_VERSION)))
#    GCC_URL = https://github.com/jcmvbkbc/gcc-xtensa/archive/xtensa-ctng-$(GCC_VERSION).zip
#    GCC_TAR = $(TAR_DIR)/gcc-xtensa-xtensa-ctng-$(GCC_VERSION).zip
#    GCC_TAR_DIR = gcc-xtensa-xtensa-ctng-$(GCC_VERSION)
    GCC_URL = https://github.com/jcmvbkbc/gcc-xtensa/archive/master.zip
    GCC_TAR = $(TAR_DIR)/gcc-xtensa-master.zip
    GCC_TAR_DIR = gcc-xtensa-master
endif

GMP_OPT   = --disable-shared --enable-static
# cygwin
GMP_CONF  =
ifneq (,$(findstring Cygwin,$(BUILD_OS)))
    GMP_CONF = --build=x86_64-unknown-cygwin
endif

CURSES_CONF  =
# Mingw
ifneq (,$(findstring Mingw,$(BUILD_OS)))
    CURSES_CONF = --build=x86_64-pc-mingw$(ARCH)
endif

WGET     := wget -cq
PATCH    := patch -s -b -N 
QUIET    := >>$(BUILD_LOG) 2>>$(ERROR_LOG)
QUIET    :=
MKDIR    := mkdir -p
RM       := rm -f
RMDIR    := rm -R -f
MOVE     := mv -f
UNTAR    := bsdtar -vxf
UNZIP    := unzip -o
MAKE_OPT := V=1 -s
MAKE_OPT :=
CONF_OPT := configure -q
CONF_OPT := configure
INST_OPT := install -s
INST_OPT := install

#BUILD_OS := Linux

ZIP_DIR_OPT = -d
ifeq (,$(findstring Linux,$(BUILD_OS)))
	UNZIP = $(UNTAR)
	ZIP_DIR_OPT = -C
endif

.PHONY: build-1

#	$(info Detected: $(BUILD_OS) on $(OS))
#	$(info Processors: $(NUMBER_OF_PROCESSORS))
#	@echo "Build:     $(BUILD_OS)"
#	@echo "BuildPath: $(BUILDPATH)"
all:
	@echo "Platform:  $(PLATFORM)"
	@mkdir -p $(DIST_DIR)
	@date > $(BUILD_LOG)
	@date > $(ERROR_LOG)
	@echo Build ist: $(BUILD_OS)
	$(MAKE) build-1

build-1: $(TOOLCHAIN) gcc

$(SOURCE_DIR):
	mkdir -p $(SOURCE_DIR)
$(TAR_DIR):
	mkdir -p $(TAR_DIR)
$(DIST_DIR):
	$(MKDIR) $(DIST_DIR)
$(COMP_LIB):
	$(MKDIR) $(COMP_LIB)
$(TOOLCHAIN): $(SOURCE_DIR) $(DIST_DIR) $(TAR_DIR) $(COMP_LIB)

$(GMP)_patch:

gmp: $(TOOLCHAIN)
	echo "Parameter BUILD_TRIPPEL: $(BUILD_TRIPPEL)"
	@$(MAKE) $(SOURCE_DIR)/.$(GMP).extracted

gcc0: $(TOOLCHAIN)
	echo $(GCC)-$(GCC_VERSION)
	make $(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).loaded
	make $(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).extracted

gcc: $(TOOLCHAIN)
#   GCC_URL = https://github.com/jcmvbkbc/gcc-xtensa/archive/master.zip
#   GCC_TAR = $(TAR_DIR)/gcc-xtensa-master.zip
#   GCC_TAR_DIR = gcc-xtensa-master
#   GCC_VERSION = xtensa
	@echo ================
	@date
#	make $(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).loaded
#	date
	$(WGET) https://github.com/jcmvbkbc/gcc-xtensa/archive/master.zip --output-document $(TAR_DIR)/gcc-xtensa-master.zip
	ls -la $(TAR_DIR)
	@echo ================
    ifneq (,$(findstring Linux,$(BUILD_OS)))
	date
	-bsdtar -vxf $(TAR_DIR)/gcc-xtensa-master.zip -C $(SOURCE_DIR)
	ls -la $(SOURCE_DIR)
#	date
	-unzip -q $(TAR_DIR)/gcc-xtensa-master.zip -d $(SOURCE_DIR)
    else
	-bsdtar -vxf $(TAR_DIR)/gcc-xtensa-master.zip -C $(SOURCE_DIR)
	ls -la $(SOURCE_DIR) $(TAR_DIR)
    endif
#	@echo ================
#	git clone https://github.com/jcmvbkbc/gcc-xtensa $(SOURCE_DIR)/gcc-xtensa-git
	@echo ================
	ls -la $(SOURCE_DIR)
	where bsdtar
	bsdtar --version


#*******************************************
#************ submodul section *************
#*******************************************
##%.extracted: %.zip
##	unzip -q $<
##%.extracted: %.tar.gz
##	$(UNTAR) $<


define Load_Modul
    @$(MKDIR) $(TAR_DIR)
    @if ! test -s $3; then echo "##########################"; fi
    @if ! test -s $3; then echo "#### Load $1..." | tee -a $(ERROR_LOG); fi
    @if ! test -s $3; then $(WGET) $2 --output-document $3 && $(RM) $(SOURCE_DIR)/.$1.*ed; fi
    @touch $(SOURCE_DIR)/.$1.loaded
endef

define Extract_Modul
    @if ! test -f $(SOURCE_DIR)/.$1-$2.extracted; then echo "$(STRIPLINE)"; fi
    @if ! test -f $(SOURCE_DIR)/.$1-$2.extracted; then echo "$(STRIP) Extract $1..." | tee -a $(ERROR_LOG); fi
    @if ( test -f $(basename $4).gz)  && (! test -f $(SOURCE_DIR)/.$1-$2.extracted); then $(RMDIR) $3 && $(UNTAR) $4 -C $(SOURCE_DIR); fi
    @if ( test -f $(basename $4).bz2) && (! test -f $(SOURCE_DIR)/.$1-$2.extracted); then $(RMDIR) $3 && $(UNTAR) $4 -C $(SOURCE_DIR); fi
    @if ( test -f $(basename $4).zip) && (! test -f $(SOURCE_DIR)/.$1-$2.extracted); then $(RMDIR) $3 && $(UNZIP) $4 $(ZIP_DIR_OPT) $(SOURCE_DIR); fi
    -@if (! test -f $(SOURCE_DIR)/.$1-$2.extracted) && (! test -f $3); then $(MOVE) $(SOURCE_DIR)/$5 $3; fi
    @touch $(SOURCE_DIR)/.$1-$2.extracted
endef

define Untar_Modul
    @if ! test -f $(SOURCE_DIR)/.$1.extracted; then echo "$(STRIPLINE)"; fi
    @if ! test -f $(SOURCE_DIR)/.$1.extracted; then echo "$(STRIP) Extract $1..." | tee -a $(ERROR_LOG); fi
    @#### Extract: if not exist $(SOURCE_DIR)/.$1.extracted then $(RMDIR) $3 && untar $4 and mv to $3
    @if ! test -f $(SOURCE_DIR)/.$1.extracted; then $(RMDIR) $3 && $(UNTAR) $4 -C $(SOURCE_DIR); fi
    -@if (! test -f $(SOURCE_DIR)/.$1.extracted) && (! test -f $3); then $(MOVE) $(SOURCE_DIR)/$5 $3; fi
	@touch $(SOURCE_DIR)/.$1.extracted
endef

define Config_Modul
    @echo "##########################"
    @echo "#### Config $1..." | tee -a $(ERROR_LOG)
    +@if ! test -f $(SOURCE_DIR)/.$1.patched; then $(MAKE) $(MAKE_OPT) $1_patch && touch $(SOURCE_DIR)/.$1.patched; fi
    @$(MKDIR) $2
    @##### Config: Path=$(SAFEPATH); cd $2 ../$(CONF_OPT) $3 $4
    PATH=$(SAFEPATH); cd $2; ../$(CONF_OPT) $3 $4 $(QUIET)
    @touch $(SOURCE_DIR)/.$1.configured
endef

define Build_Modul
    @echo "##########################"
    @echo "#### Build $1..." | tee -a $(ERROR_LOG)
    @#### Build: Path=$(SAFEPATH); $3 $(MAKE) $(MAKE_OPT) $4 -C $2
    @#### for '+' token see https://www.gnu.org/software/make/manual/html_node/Error-Messages.html
    +PATH=$(SAFEPATH); $3 $(MAKE) $(MAKE_OPT) $4 -C $2 $(QUIET)
    @touch $(SOURCE_DIR)/.$1.builded
endef

define Install_Modul
    @echo "##########################"
    @echo "#### Install $1..." | tee -a $(ERROR_LOG)
    @echo "##########################"
    @#### "Install: Path=$(SAFEPATH); $(MAKE) $(MAKE_OPT) $3=$(INST_OPT) -C $2"
    +PATH=$(SAFEPATH); $(MAKE) $(MAKE_OPT) $3 -C $2 $(QUIET)
    @$(OUTPUT_DATE)
    @touch $(SOURCE_DIR)/.$1.installed
endef

define Modul_Load
   @if ! ./Load_Modul.sh $1 $2 $3; then echo "#### $1 exitiert bereits"; fi
endef

define Modul_Extract
   @if ! ./Extract_Modul.sh $1 $2 $3 $4; then echo "#### $1 bereits entpackt"; fi
endef

#************** GMP (GNU Multiple Precision Arithmetic Library)
$(SOURCE_DIR)/.$(GMP).loaded:
	$(call Load_Modul,$(GMP),$(GMP_URL),$(GMP_TAR))
$(SOURCE_DIR)/.$(GMP).extracted: $(SOURCE_DIR)/.$(GMP).loaded
	$(call Extract_Modul,$(GMP),$(GMP_VERSION),$(GMP_DIR),$(GMP_TAR),$(GMP_TAR_DIR))
$(SOURCE_DIR)/.$(GMP).configured: $(SOURCE_DIR)/.$(GMP).extracted
	$(call Config_Modul,$(GMP),$(BUILD_GMP_DIR),$(GMP_CONF) --prefix=$(COMP_LIB)/$(GMP)-$(GMP_VERSION),$(GMP_OPT))
$(SOURCE_DIR)/.$(GMP).builded: $(SOURCE_DIR)/.$(GMP).configured
	$(call Build_Modul,$(GMP),$(BUILD_GMP_DIR))
$(SOURCE_DIR)/.$(GMP).installed: $(SOURCE_DIR)/.$(GMP).builded
	$(call Install_Modul,$(GMP),$(BUILD_GMP_DIR),$(INST_OPT))

#************** GCC (The GNU C preprocessor)
$(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).loaded:
	$(call Load_Modul,$(GCC),$(GCC_URL),$(GCC_TAR))
$(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).extracted: $(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).loaded
	$(call Extract_Modul,$(GCC),$(GCC_VERSION),$(GCC_DIR),$(GCC_TAR),$(GCC_TAR_DIR))
