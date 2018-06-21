# Author: Peter Dobler (@Juppit)
#
# Last edit: 28.04.2018

BUILDPATH = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:

PLATFORM := $(shell uname -s)
ifneq (,$(findstring 64, $(shell uname -m)))
    ARCH = 64
else
    ARCH = 32
endif

BUILD := $(PLATFORM)
ifeq ($(OS),Windows_NT)
    ifneq (,$(findstring MINGW32,$(PLATFORM)))
        BUILD := Mingw$(ARCH)
        BUILDPATH := /mingw$(ARCH)/bin:$(BUILDPATH)
    endif
    ifneq (,$(findstring MINGW64,$(PLATFORM)))
        BUILD := Mingw$(ARCH)
        BUILDPATH := /mingw$(ARCH)/bin:$(BUILDPATH)
    endif
    ifneq (,$(findstring MSYS,$(PLATFORM)))
        BUILD := MSYS$(ARCH)
        BUILDPATH := /msys$(ARCH)/usr/bin:$(BUILDPATH)
    endif
    ifneq (,$(findstring CYGWIN,$(PLATFORM)))
        BUILD := Cygwin$(ARCH)
    endif
    ifneq (,$(findstring Cygwin,$(PLATFORM)))
        BUILD := Cygwin$(ARCH)
    endif
else
    ifeq ($(PLATFORM),Darwin)
        BUILD := MacOS$(ARCH)
    endif
    ifeq ($(PLATFORM),Linux)
        ifneq (,$(findstring ARM,$(PLATFORM)))
            BUILD := LinuxARM$(ARCH)
        else
            BUILD := Linux$(ARCH)
        endif
        ifneq (,$(findstring ARCH64,$(PLATFORM)))
            BUILD := LinuxARM$(ARCH)
        endif
    endif
endif

# various hosts are not supported like 'darwin'
#HOST   = x86_64-apple-darwin14.0.0
TARGET = xtensa-lx106-elf

# create tar-file for distribution
DISTRIB  = ""
DISTRIB  = $(BUILD)-$(TARGET)
USE_DISTRIB = y

TOP = $(PWD)

TOOLCHAIN = $(TOP)/$(TARGET)
TARGET_DIR = $(TOOLCHAIN)/$(TARGET)

SAFEPATH = "$(TOOLCHAIN)/bin:"$(BUILDPATH)

COMP_LIB = $(TOP)/comp_libs
SOURCE_DIR = $(TOP)/src
TAR_DIR = $(TOP)/tarballs
PATCHES_DIR = $(SOURCE_DIR)/patches
BUILD_DIR = build-$(BUILD)
DIST_DIR = $(TOP)/distrib

OUTPUT_DATE = date +"%Y-%m-%d %X" 

# Log file
BUILD_LOG = $(DIST_DIR)/$(BUILD)-build.log
ERROR_LOG = $(DIST_DIR)/$(BUILD)-error.log

GNU_URL = https://ftp.gnu.org/gnu

GMP_VERSION = 6.1.2
CURSES_VERSION  = 6.1
GCC_VERSION  = 8.1.0

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

CURSES = ncurses
CURSES_DIR = $(SOURCE_DIR)/$(CURSES)-$(CURSES_VERSION)
BUILD_CURSES_DIR = $(CURSES_DIR)/$(BUILD_DIR)
CURSES_URL = $(GNU_URL)/$(CURSES)/$(CURSES)-$(CURSES_VERSION).tar.gz
CURSES_TAR = $(TAR_DIR)/$(CURSES)-$(CURSES_VERSION).tar.bz2
CURSES_TAR_DIR = $(CURSES)-$(CURSES_VERSION)

EXPAT = expat
EXPAT_DIR = $(SOURCE_DIR)/$(EXPAT)-$(EXPAT_VERSION)
BUILD_EXPAT_DIR = $(EXPAT_DIR)/$(BUILD_DIR)
EXPAT_URL = https://github.com/libexpat/libexpat/releases/download/R_2_1_0/expat-2.1.0.tar.gz
ifneq (,$(findstring 2.1.0,$(EXPAT_VERSION)))
    EXPAT_URL = https://github.com/libexpat/libexpat/releases/download/R_2_1_0/expat-2.1.0.tar.gz
endif
EXPAT_TAR = $(TAR_DIR)/$(EXPAT)-$(EXPAT_VERSION).tar.gz
EXPAT_TAR_DIR = $(EXPAT)-$(EXPAT_VERSION)

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
ifneq (,$(findstring Cygwin,$(BUILD)))
    GMP_CONF = --build=x86_64-unknown-cygwin
endif

CURSES_OPT = --enable-symlinks --without-manpages --without-tests \
              --without-cxx --without-cxx-binding --without-ada
CURSES_CONF  =
# Mingw
ifneq (,$(findstring Mingw,$(BUILD)))
    CURSES_OPT = --enable-symlinks --without-manpages --without-tests \
                 --without-cxx --without-cxx-binding --without-ada \
                 --enable-term-driver --enable-sp-funcs
    CURSES_CONF = --build=x86_64-pc-mingw$(ARCH)
endif

EXPAT_OPT =

WGET     := wget -cq
PATCH    := patch -s -b -N 
QUIET    := >>$(BUILD_LOG) 2>>$(ERROR_LOG)
QUIET    :=
MKDIR    := mkdir -p
RM       := rm -f
RMDIR    := rm -R -f
MOVE     := mv -f
UNTAR    := bsdtar -xf
MAKE_OPT := V=1 -s
CONF_OPT := configure -q
INST_OPT := install -s

.PHONY: build-1 build-2 build-3

all:
	$(info Detected: $(BUILD) on $(OS))
	$(info Processors: $(NUMBER_OF_PROCESSORS))
	@echo "Build:     $(BUILD)"
	@echo "BuildPath: $(BUILDPATH)"
	@echo "Platform:  $(PLATFORM)"
	@mkdir -p $(DIST_DIR)
	@date > $(BUILD_LOG)
	@date > $(ERROR_LOG)
    ifneq (,$(findstring CYGWIN,$(BUILD)))
		@echo BUILD ist: $(BUILD)
    endif
    ifneq (,$(findstring Cygwin,$(BUILD)))
		@echo Build ist: $(BUILD)
    endif
	$(MAKE) build-3
###	$(MAKE) build-2

#build-1: $(TOOLCHAIN) gmp if_expat
build-1: $(TOOLCHAIN) guess
build-2: $(TOOLCHAIN) if_curses
build-3: $(TOOLCHAIN) gcc

$(SOURCE_DIR):
	@mkdir -p $(SOURCE_DIR)
$(TAR_DIR):
	@mkdir -p $(TAR_DIR)
$(DIST_DIR):
	@$(MKDIR) $(DIST_DIR)
$(COMP_LIB):
	@$(MKDIR) $(COMP_LIB)
$(TOOLCHAIN): $(SOURCE_DIR) $(DIST_DIR) $(TAR_DIR) $(COMP_LIB)

$(GMP)_patch:
$(CURSES)_patch:

guess: $(TOOLCHAIN)
	echo "Parameter BUILD_TRIPPEL: $(BUILD_TRIPPEL)"
	@echo "**** new config.guess"
	-./config.guess
	@echo "**** uname -a:"
	@uname -a
	@echo "**** start configure gmp"
	@$(MAKE) $(SOURCE_DIR)/.$(GMP).extracted
	@echo "**** start config.guess"
	-cd $(GMP_DIR) && ./config.guess
	@echo "**** end gmp"

gmp: $(TOOLCHAIN)
	echo "Parameter BUILD_TRIPPEL: $(BUILD_TRIPPEL)"
	@echo "**** new config.guess"
	-./config.guess
	@echo "**** uname -a:"
	@uname -a
	@echo "**** start configure gmp"
	@$(MAKE) $(SOURCE_DIR)/.$(GMP).extracted
	@echo "**** start config.guess"
	-cd $(GMP_DIR) && ./config.guess
	@echo "**** end gmp"

if_expat: $(TOOLCHAIN)
#	@PATH="$(SAFEPATH)" $(MAKE) $(SOURCE_DIR)/.$(EXPAT).extracted
if_curses: $(TOOLCHAIN)
	@PATH="$(SAFEPATH)" $(MAKE) $(SOURCE_DIR)/.$(CURSES).installed

gcc: $(TOOLCHAIN)
	echo $(GCC)-$(GCC_VERSION)
	make $(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).loaded
	date
	make $(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).extracted
	date
#   GCC_URL = https://github.com/jcmvbkbc/gcc-xtensa/archive/master.zip
#   GCC_TAR = $(TAR_DIR)/gcc-xtensa-master.zip
#   GCC_TAR_DIR = gcc-xtensa-master
#   GCC_VERSION = xtensa
	$(WGET) https://github.com/jcmvbkbc/gcc-xtensa/archive/call0-4.9.2.zip --output-document $(TAR_DIR)/gcc-xtensa-call0-4.9.2.zip
	$(WGET) https://github.com/jcmvbkbc/gcc-xtensa/archive/xtensa-ctng-esp-5.2.0.zip --output-document $(TAR_DIR)/gcc-xtensa-xtensa-ctng-esp-5.2.0.zip
	$(WGET) https://github.com/jcmvbkbc/gcc-xtensa/archive/xtensa-ctng-7.2.0.zip --output-document $(TAR_DIR)/gcc-xtensa-xtensa-ctng-7.2.0.zip
	$(WGET) https://github.com/jcmvbkbc/gcc-xtensa/archive/master.zip --output-document $(TAR_DIR)/gcc-xtensa-master.zip
	date
	ls -l $(TAR_DIR)
	echo ================
    ifneq (,$(findstring Linux,$(BUILD)))
	-unzip -q $(TAR_DIR)/gcc-xtensa-call0-4.9.2.zip -d $(SOURCE_DIR)
	-unzip -q $(TAR_DIR)/gcc-xtensa-xtensa-ctng-esp-5.2.0.zip -d $(SOURCE_DIR)
	-unzip -q $(TAR_DIR)/gcc-xtensa-xtensa-ctng-7.2.0.zip -d $(SOURCE_DIR)
	-unzip -q $(TAR_DIR)/gcc-xtensa-master.zip -d $(SOURCE_DIR)
	-$(UNTAR) $(TAR_DIR)/gcc-xtensa-master.zip -C $(SOURCE_DIR)
    else
	-$(UNTAR) $(TAR_DIR)/gcc-xtensa-call0-4.9.2.zip -C $(SOURCE_DIR)
	-$(UNTAR) $(TAR_DIR)/gcc-xtensa-xtensa-ctng-esp-5.2.0.zip -C $(SOURCE_DIR)
	-$(UNTAR) $(TAR_DIR)/gcc-xtensa-xtensa-ctng-7.2.0.zip -C $(SOURCE_DIR)
	-$(UNTAR) $(TAR_DIR)/gcc-xtensa-master.zip -C $(SOURCE_DIR)
    endif
	date
	ls -l $(SOURCE_DIR)

#*******************************************
#************ submodul section *************
#*******************************************

define Load_Modul
	@$(MKDIR) $(TAR_DIR)
	@if ! test -s $3; then echo "##########################"; fi
	@if ! test -s $3; then echo "#### Load $1..." | tee -a $(ERROR_LOG); fi
	@if ! test -s $3; then $(WGET) $2 --output-document $3 && $(RM) $(SOURCE_DIR)/.$1.*ed; fi
	@touch $(SOURCE_DIR)/.$1.loaded
endef

define Extract_Modul
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

#************** EXPAT
$(SOURCE_DIR)/.$(EXPAT).loaded:
	$(call Load_Modul,$(EXPAT),$(EXPAT_URL),$(EXPAT_TAR))
$(SOURCE_DIR)/.$(EXPAT).extracted: $(SOURCE_DIR)/.$(EXPAT).loaded
	$(call Extract_Modul,$(EXPAT),$(EXPAT_VERSION),$(EXPAT_DIR),$(EXPAT_TAR),$(EXPAT_TAR_DIR))
$(SOURCE_DIR)/.$(EXPAT).configured: $(SOURCE_DIR)/.$(EXPAT).extracted
	$(call Config_Modul,$(EXPAT),$(BUILD_EXPAT_DIR),--prefix=$(COMP_LIB)/$(EXPAT)-$(EXPAT_VERSION),$(EXPAT_OPT))
$(SOURCE_DIR)/.$(EXPAT).builded: $(SOURCE_DIR)/.$(EXPAT).configured
	$(call Build_Modul,$(EXPAT),$(BUILD_EXPAT_DIR))
$(SOURCE_DIR)/.$(EXPAT).installed: $(SOURCE_DIR)/.$(EXPAT).builded
	$(call Install_Modul,$(EXPAT),$(BUILD_EXPAT_DIR),$(INST_OPT))

#************** CURSES
$(SOURCE_DIR)/.$(CURSES).loaded:
	$(call Load_Modul,$(CURSES),$(CURSES_URL),$(CURSES_TAR))
$(SOURCE_DIR)/.$(CURSES).extracted: $(SOURCE_DIR)/.$(CURSES).loaded
	$(call Extract_Modul,$(CURSES),$(CURSES_VERSION),$(CURSES_DIR),$(CURSES_TAR),$(CURSES_TAR_DIR))
$(SOURCE_DIR)/.$(CURSES).configured: $(SOURCE_DIR)/.$(CURSES).extracted
	$(call Config_Modul,$(CURSES),$(BUILD_CURSES_DIR),$(CURSES_CONF) --prefix=$(COMP_LIB)/$(CURSES)-$(CURSES_VERSION),$(CURSES_OPT))
$(SOURCE_DIR)/.$(CURSES).builded: $(SOURCE_DIR)/.$(CURSES).configured
	$(call Build_Modul,$(CURSES),$(BUILD_CURSES_DIR))
$(SOURCE_DIR)/.$(CURSES).installed: $(SOURCE_DIR)/.$(CURSES).builded
	$(call Install_Modul,$(CURSES),$(BUILD_CURSES_DIR),$(INST_OPT))

#************** GCC (The GNU C preprocessor)
$(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).loaded:
	$(call Load_Modul,$(GCC),$(GCC_URL),$(GCC_TAR))
$(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).extracted: $(SOURCE_DIR)/.$(GCC)-$(GCC_VERSION).loaded
	$(call Extract_Modul,$(GCC),$(GCC_VERSION),$(GCC_DIR),$(GCC_TAR),$(GCC_TAR_DIR))
