#
# MIT License
#
# Copyright (c) 2020 Zakhary Kaplan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# <https://github.com/zakharykaplan/cake>

# --------------------------------
#          Configuration
# --------------------------------

# {{{
# Root directory
ROOT ?= .

# Makefiles
MAKEFILE = $(firstword $(MAKEFILE_LIST))
CAKEFILE = $(ROOT)/Cake.mk

# Goals
.DEFAULT_GOAL := all # explicitly set default goal

# User configuration
-include $(CAKEFILE)

# Package
NAME    ?= $(shell basename '$(PWD)')
VERSION ?= $(shell date +%s)
# }}}


# --------------------------------
#              Macros
# --------------------------------

# {{{
# Find a path relative to a directory
# - $(1): base path
# - $(2): relative directory
relpath = $(shell realpath -m $(1) --relative-to $(2))

# Select an item from a list
# - $(1): user selected default
# - $(2): list of items to select from
selector = $(or $(firstword $(foreach ITEM,$(2),$(if $($(ITEM)),$(ITEM)))), \
                $(if $($(1)),,$(firstword $(2))),                           \
                $(filter $($(1)),$(2)),                                     \
                $(error invalid $(1): `$($(1))`))
# }}}


# --------------------------------
#            Variables
# --------------------------------

# {{{
# -- Directories --
# Input directories
INCLUDE ?= $(ROOT)/include
SRC     ?= $(ROOT)/src
TEST    ?= $(ROOT)/test
# Source subdirectories
SBIN = $(SRC)/bin
SLIB = $(SRC)/lib
# Output directories
BUILD ?= $(ROOT)/build
BIN   ?= $(ROOT)/bin
LIB   ?= $(ROOT)/lib
# Build subdirectories
BBIN   = $(BUILD)/bin
BLIB   = $(BUILD)/lib
DEP    = $(BUILD)/dep
OBJ    = $(BUILD)/obj
# Install directories
LOCAL ?= /usr/local
IROOT  = $(LOCAL)/$(NAME)
LBIN   = $(LOCAL)/bin
LINC   = $(LOCAL)/include
LLIB   = $(LOCAL)/lib

# -- Build --
# Determine build mode
MODES     := BASIC DEBUG RELEASE
CONFIG    := $(call selector,CONFIG,$(MODES))
# Set build mode parameters
ifeq      ($(CONFIG),BASIC)   # basic build
else ifeq ($(CONFIG),DEBUG)   # debug build
BUILD    := $(BUILD)/debug
CPPFLAGS += -O0 -g3 -DDEBUG
else ifeq ($(CONFIG),RELEASE) # release build
BUILD    := $(BUILD)/release
CPPFLAGS += -O3 -g0 -DNDEBUG
endif

# -- Extensions --
# Dependencies
.d  ?= .d
# Objects
.a  ?= .a
.o  ?= .o
.so ?= .so
# Sources
.c  ?= .c
.cc ?= .cpp
.h  ?= .h

# -- Files --
# Sources
HEADERS    := $(shell find -L $(ROOT) -name "*$(.h)")
CSOURCES   := $(shell find -L $(ROOT) -name "*$(.c)")
CXXSOURCES := $(shell find -L $(ROOT) -name "*$(.cc)")
SOURCES     = $(CSOURCES) $(CXXSOURCES)
# Special sources
CMAIN   = $(wildcard $(SRC)/main$(.c))
CXXMAIN = $(wildcard $(SRC)/main$(.cc))
MAIN    = $(lastword $(CMAIN) $(CXXMAIN))
MAINDEP = $(if $(MAIN),$(DEP)/$(NAME)$(.d))
MAINOBJ = $(if $(MAIN),$(OBJ)/$(NAME)$(.o))
# Prerequisites (filtered)
CBINS   := $(filter $(SBIN)/%,$(CSOURCES))
CXXBINS := $(filter $(SBIN)/%,$(CXXSOURCES))
CLIBS   := $(filter $(SLIB)/%,$(CSOURCES))
CXXLIBS := $(filter $(SLIB)/%,$(CXXSOURCES))
CSRCS   := $(filter $(SRC)/%,$(CSOURCES))
CSRCS   := $(filter-out $(SBIN)/% $(SLIB)/%,$(CSRCS))
CSRCS   := $(filter-out $(CMAIN),$(CSRCS))
CXXSRCS := $(filter $(SRC)/%,$(CXXSOURCES))
CXXSRCS := $(filter-out $(SBIN)/% $(SLIB)/%,$(CXXSRCS))
CXXSRCS := $(filter-out $(CXXMAIN),$(CXXSRCS))
CTSTS   := $(filter $(TEST)/%,$(CSOURCES))
CXXTSTS := $(filter $(TEST)/%,$(CXXSOURCES))
# Prerequisites (combined)
SBINS := $(CBINS) $(CXXBINS) $(MAIN)
SLIBS := $(CLIBS) $(CXXLIBS)
SSRCS := $(CSRCS) $(CXXSRCS)
STSTS := $(CTSTS) $(CXXTSTS)
# Object targets (filtered)
CBINOS   = $(CBINS:$(SBIN)/%$(.c)=$(OBJ)/%$(.o))
CXXBINOS = $(CXXBINS:$(SBIN)/%$(.cc)=$(OBJ)/%$(.o))
CLIBOS   = $(CLIBS:$(SLIB)/%$(.c)=$(OBJ)/%$(.o))
CXXLIBOS = $(CXXLIBS:$(SLIB)/%$(.cc)=$(OBJ)/%$(.o))
CSRCOS   = $(CSRCS:$(SRC)/%$(.c)=$(OBJ)/%$(.o))
CXXSRCOS = $(CXXSRCS:$(SRC)/%$(.cc)=$(OBJ)/%$(.o))
CTSTOS   = $(CTSTS:$(ROOT)/%$(.c)=$(OBJ)/%$(.o))
CXXTSTOS = $(CXXTSTS:$(ROOT)/%$(.cc)=$(OBJ)/%$(.o))
# Object targets (combined)
BINOBJS = $(CBINOS) $(CXXBINOS) $(MAINOBJ)
LIBOBJS = $(CLIBOS) $(CXXLIBOS)
SRCOBJS = $(CSRCOS) $(CXXSRCOS)
TSTOBJS = $(CTSTOS) $(CXXTSTOS)
OBJS    = $(BINOBJS) $(LIBOBJS) $(SRCOBJS)
# Include targets
INCS = $(filter $(INCLUDE)/%,$(HEADERS))
# Binary targets
BINS     := $(BINOBJS:$(OBJ)/%$(.o)=$(BBIN)/%)
BINLINKS  = $(BINS:$(BBIN)/%=$(BIN)/%)
BINNAMES  = $(BINS:$(BBIN)/%=%)
# Dependency targets
DEPS := $(OBJS:$(OBJ)/%$(.o)=$(DEP)/%$(.d))
# Library targets
LIBDS    := $(sort $(patsubst %/,%,$(dir $(SLIBS))))
LIBDS    := $(filter $(LIBDS),$(wildcard $(SLIB)/*))
LIBARS    = $(LIBDS:$(SLIB)/%=$(BLIB)/lib%$(.a))
LIBSOS    = $(LIBDS:$(SLIB)/%=$(BLIB)/lib%$(.so))
LIBS     := $(LIBARS) $(LIBSOS)
LIBLINKS  = $(LIBS:$(BLIB)/%=$(LIB)/%)
LIBNAMES  = $(LIBDS:$(SLIB)/%=%)
# Test targets
TESTS     := $(TSTOBJS:$(OBJ)/%$(.o)=$(BBIN)/%)
TESTNAMES  = $(TESTS:$(BBIN)/%=%)
# Install targets
LBINS = $(BINS:$(BBIN)/%=$(LBIN)/%)
LINCS = $(INCS:$(INCLUDE)/%=$(LINC)/%)
LLIBS = $(LIBS:$(BLIB)/%=$(LLIB)/%)
# Source targets
TAGFILE   ?= $(BUILD)/tags
TARDIR    ?= $(NAME)-$(VERSION)
TARFILE    = $(TARDIR).tar.gz
DISTFILES ?= $(or $(shell git ls-files 2> $(DEVNULL)),    \
                  $(MAKEFILE_LIST) $(HEADERS) $(SOURCES))

# -- Miscellaneous --
# Commands
CHECK = clang-tidy
CP    = cp -fLR
FIX   = clang-tidy --fix-errors
FMT   = clang-format --verbose -i
LN    = ln -sf
MKDIR = mkdir -p
RM    = rm -rf
TAGS  = ctags
TAR   = tar
# Compilers
AR   = ar
CC  ?= cc
CXX ?= c++
# Devices
DEVNULL = /dev/null
# Flags
ARFLAGS   = crs
CFLAGS   ?= -Wall -g -std=c18
CPPFLAGS += $(INCLUDES)
CXXFLAGS ?= -Wall -g -std=c++20
DEPFLAGS  = -MM -MF $@ -MT $(OBJ)/$*$(.o)
LDFLAGS  +=
LDLIBS   +=
TARFLAGS  = -zchvf
# Flag partials
INCLUDES  = $(addprefix -I,$(wildcard $(INCLUDE)))
LIBRARIES = $(addprefix -L,$(if $(LIBDS),$(BLIB)))
LIBFLAGS  = $(addprefix -l,$(LIBNAMES))

# -- Linkage --
# Determine linkage mode
MODES      := STATIC DYNAMIC
LINKAGE    := $(call selector,LINKAGE,$(MODES))
# Set linkage parameters
ifeq      ($(LINKAGE),STATIC)  # static linkage
$(BINS) $(TESTS): LDLIBS  += $(LIBARS)
$(BINS) $(TESTS): $(LIBARS)
else ifeq ($(LINKAGE),DYNAMIC) # dynamic linkage
$(BINS) $(TESTS): LDFLAGS += $(LIBRARIES) # libraries should be linked...
$(BINS) $(TESTS): LDLIBS  += $(LIBFLAGS)  # ...when building an binary
$(BINS) $(TESTS): $(LIBSOS)
endif
# }}}


# --------------------------------
#             Asserts
# --------------------------------

# {{{
# -- Configuration --
# Package name
ifneq ($(words $(NAME)),1)
$(error Package name cannot contain whitespace)
endif

# -- Directories --
SUBROOT = $(INCLUDE) $(SRC) $(SBIN) $(SLIB) $(TEST)
# Detached source directories
ifneq ($(filter-out $(ROOT)/%,$(SUBROOT)),)
$(error Detached source directories)
endif

# -- Extensions --
EXTENSIONS = $(.a) $(.c) $(.cc) $(.d) $(.h) $(.o) $(.so)
# C and C++ sources
ifeq ($(.c),$(.cc))
$(error Cannot use extension `$(.c)` for both C and C++ sources)
endif
# Catchall extension collision
ifneq ($(words $(sort $(EXTENSIONS))),$(words $(EXTENSIONS)))
$(error Cannot reuse extensions for multiple file types)
endif
# Extensions without dot prefix
ifneq ($(filter-out .%,$(EXTENSIONS)),)
$(error Found extensions without dot prefix)
endif

# -- Files --
# Duplicate objects
ifneq ($(words $(sort $(OBJS))),$(words $(OBJS)))
$(error Found duplicate object source files)
endif
# Incorrecly placed library sources
ifneq ($(wildcard $(SLIB)/*$(.c) $(SLIB)/*$(.cc)),)
$(error Incorrecly placed library source files)
endif

# -- Runtime --
# Disallow multiple make command goals
ifneq ($(words $(or $(MAKECMDGOALS),$(.DEFAULT_GOAL))),1)
$(error Multiple make command goals)
endif
# }}}


# --------------------------------
#           Basic Goals
# --------------------------------

# {{{
# Make all targets
.PHONY: all
all: build

# Make alternate builds
.PHONY: debug
debug: export CONFIG = DEBUG
debug:
	@$(MAKE) all

.PHONY: release
release: export CONFIG = RELEASE
release:
	@$(MAKE) all
# }}}


# --------------------------------
#           Build Goals
# --------------------------------

# {{{
# Build all targets
.PHONY: b build
b: build
build: bin dep lib obj

# Rebuild all targets
.PHONY: rebuild
rebuild: clean
	@$(MAKE) build

# Create symlinks
$(BINLINKS) $(LIBLINKS): $(ROOT)/%: $(BUILD)/% FORCE
	@$(MKDIR) $(@D)
	@$(LN) $(call relpath,$<,$(@D)) $@

# Build binaries
.PHONY: bin
bin: $(BINS) $(BINLINKS)

# Link target binaries
$(BBIN)/%: $(OBJ)/%$(.o) $(SRCOBJS)
	@$(MKDIR) $(@D)
	$(LINK.cc) -o $@ $< $(SRCOBJS) $(LDLIBS)

# Run target binary by name
.PHONY: r run
r: run
ifeq ($(words $(BINNAMES)),1)
run: $(BINNAMES)
else
run:
	$(warning Could not determine which binary to run.)
	$(warning Use `make <binary>` to speficy a binary target.)
	$(error Available binaries: $(or $(BINNAMES),NONE))
endif

$(BINNAMES): %: $(BIN)/% FORCE
	@$< $(ARGS)

# Generate dependency files
.PHONY: dep
dep: $(DEPS)

$(DEP)/%$(.d): LDFLAGS = # generate dependencies without linker flags

$(DEP)/%$(.d): %$(.c)
	@$(MKDIR) $(@D)
	@$(LINK.c) $(DEPFLAGS) $<

$(DEP)/%$(.d): %$(.cc)
	@$(MKDIR) $(@D)
	@$(LINK.cc) $(DEPFLAGS) $<

$(MAINDEP): $(DEP)/%$(.d): $(MAIN) # special case
	@$(MKDIR) $(@D)
ifeq ($(MAIN),$(CMAIN))
	@$(LINK.c) $(DEPFLAGS) $<
else
	@$(LINK.cc) $(DEPFLAGS) $<
endif

# Create libraries
.PHONY: lib
lib: $(LIBS) $(LIBLINKS)

$(LIBOBJS): CPPFLAGS += -fPIC # compile libraries with PIC

# Combine library archives
.SECONDEXPANSION:
$(BLIB)/lib%$(.a): $$(filter $(OBJ)/%/$$(PERCENT),$(OBJS))
	@$(MKDIR) $(@D)
	$(AR) $(ARFLAGS) $@ $^

# Link library shared objects
.SECONDEXPANSION:
$(BLIB)/lib%$(.so): LDFLAGS += -shared
$(BLIB)/lib%$(.so): $$(filter $(OBJ)/%/$$(PERCENT),$(OBJS))
	@$(MKDIR) $(@D)
	$(LINK.cc) -o $@ $^ $(LDLIBS)

# Create target library by name
$(LIBNAMES): %: $(LIB)/lib%$(.a) $(LIB)/lib%$(.so) FORCE

# Compile object files
.PHONY: obj
obj: $(OBJS)

$(OBJ)/%$(.o): %$(.c) | $(DEP)/%$(.d)
	@$(MKDIR) $(@D)
	$(COMPILE.c) -o $@ $<

$(OBJ)/%$(.o): %$(.cc) | $(DEP)/%$(.d)
	@$(MKDIR) $(@D)
	$(COMPILE.cc) -o $@ $<

$(MAINOBJ): $(MAIN) | $(MAINDEP) # special case
	@$(MKDIR) $(@D)
ifeq ($(MAIN),$(CMAIN))
	$(COMPILE.c) -o $@ $<
else
	$(COMPILE.cc) -o $@ $<
endif

# Compile and run tests
.PHONY: t test
t: test
test: | $(filter-out t test,$(MAKECMDGOALS)) # always run tests last
	@$(foreach TEST,$(TESTNAMES),$(MAKE) $(TEST);)

.PHONY: $(TESTNAMES)
$(TESTNAMES): %: $(BBIN)/%
	@echo -n Running $(@F)...
	@$< &> $(DEVNULL)      \
                && echo done   \
                || echo failed
# }}}


# --------------------------------
#           Clean Goals
# --------------------------------

# {{{
# Clean build directory
.PHONY: clean
clean:
	@$(RM) -v $(BIN) $(LIB) $(BUILD)

# Clean binaries
.PHONY: binclean
binclean:
	@$(RM) -v $(BIN) $(BBIN)

# Clean dependencies
.PHONY: depclean
depclean:
	@$(RM) -v $(DEP)

# Clean libraries
.PHONY: libclean
libclean:
	@$(RM) -v $(LIB) $(BLIB)

# Clean objects
.PHONY: objclean
objclean:
	@$(RM) -v $(OBJ)
# }}}


# --------------------------------
#          Install Goals
# --------------------------------

# {{{
$(shell test -w $(LOCAL)) # test for write permissions
ifeq ($(.SHELLSTATUS),)
.SHELLSTATUS = $(shell test -w $(LOCAL); echo $$?)
endif

# Install build targets
.PHONY: install
NOINSTALL := $(addprefix $(LOCAL)/,$(NOINSTALL))
INSTALL   ?= $(LBINS) $(LINCS) $(LLIBS)
INSTALL   := $(filter-out $(NOINSTALL),$(INSTALL))
ifeq ($(.SHELLSTATUS),0)
install: $(INSTALL)
else
install:
ifeq ($(INSTALL),)
	$(error Nothing to install)
endif
	$(warning The following files will be created:)
	$(foreach FILE,                                                  \
                  $(INSTALL),                                            \
                  $(warning - $(FILE) -> $(FILE:$(LOCAL)/%=$(IROOT)/%)))
	$(error Insufficient permissions for `$(LOCAL)`)
endif

$(LOCAL)/%: $(IROOT)/%
	@$(MKDIR) $(@D)
	@$(LN) -vi $(call relpath,$<,$(@D)) $@

$(IROOT)/%: $(ROOT)/%
	@$(MKDIR) $(@D)
	@$(CP) -vi $< $@

# Uninstall build targets
.PHONY: uninstall
UNINSTALL := $(wildcard $(IROOT) $(LBINS) $(LINCS) $(LLIBS))
uninstall:
ifeq ($(.SHELLSTATUS),0)
	@$(RM) -v $(UNINSTALL)
else ifeq ($(UNINSTALL),)
	$(error Nothing to uninstall)
else
	$(warning The following files will be removed:)
	$(foreach FILE,$(UNINSTALL),$(warning - $(FILE)))
	$(error Insufficient permissions for `$(LOCAL)`)
endif
# }}}


# --------------------------------
#           Source Goals
# --------------------------------

# {{{
# Check sources
.PHONY: c check
c: check
check:
	@$(CHECK) $(SOURCES) -- $(INCLUDES)

# Create distribution tar file
.PHONY: dist
dist: $(BUILD)/$(TARFILE)

$(BUILD)/$(TARFILE): $(TARDIR)
	@$(MKDIR) $(@D)
	@$(TAR) $(TARFLAGS) $@ $<
	@$(RM) $<

$(TARDIR): $(DISTFILES:%=$(TARDIR)/%)

$(TARDIR)/%: %
	@$(MKDIR) $(@D)
	@$(LN) -vi $(call relpath,$<,$(@D)) $@

# Fix sources
.PHONY: fix
fix:
	@$(FIX) $(SOURCES) -- $(INCLUDES)

# Format sources
.PHONY: fmt
fmt:
	@$(FMT) $(HEADERS) $(SOURCES)

# Generate tag files
.PHONY: tag
tag: $(TAGFILE)

$(TAGFILE): $(HEADERS) $(SOURCES)
	@$(MKDIR) $(dir $(TAGFILE))
	@$(TAGS) -f $@ $^
# }}}


# --------------------------------
#            Echo Goals
# --------------------------------

# {{{
# About target
.PHONY: about
about:
ifdef NAME
	@echo '$(NAME)' '$(VERSION)'
endif
ifdef AUTHOR
	@echo '$(AUTHOR)'
endif
ifdef DESCRIPTION
	@echo '$(DESCRIPTION)'
endif

# Config target
.PHONY: config
config: about
	@echo
	@echo 'BUILD:'
	@echo "\t"'CONFIG    = $(CONFIG)'
	@echo "\t"'LINKAGE   = $(LINKAGE)'
	@echo
	@echo 'COMPILER:'
	@echo "\t"'C         = $(CC)'
	@echo "\t"'CXX       = $(CXX)'
	@echo
	@echo 'DIRECTORIES:'
	@echo "\t"'ROOT      = $(ROOT)'
	@echo "\t"'BIN       = $(BIN)'
	@echo "\t"'BUILD     = $(BUILD)'
	@echo "\t"'INCLUDE   = $(INCLUDE)'
	@echo "\t"'LIB       = $(LIB)'
	@echo "\t"'SRC       = $(SRC)'
	@echo "\t"'TEST      = $(TEST)'
	@echo "\t"'LOCAL     = $(LOCAL)'
	@echo
	@echo 'FILES:'
	@echo "\t"'TAGFILE   = $(TAGFILE)'
	@echo "\t"'TARDIR    = $(TARDIR)'
	@echo
	@echo 'FLAGS:'
	@echo "\t"'CFLAGS    = $(CFLAGS)'
	@echo "\t"'CPPFLAGS  = $(CPPFLAGS)'
	@echo "\t"'CXXFLAGS  = $(CXXFLAGS)'
	@echo "\t"'LDFLAGS   = $(LDFLAGS)'
	@echo "\t"'LDLIBS    = $(LDLIBS)'

# Help target
.PHONY: help
help: about
	@echo
	@echo 'USAGE:'
	@echo "\t"'make [TARGET]'
	@echo
	@echo 'TARGETS:'
	@echo "\t"'all           Alias for `build`. (default)'
	@echo "\t"'debug         Make debug build.'
	@echo "\t"'release       Make release build.'
	@echo
	@echo "\t"'build, b      Build all targets.'
	@echo "\t"'rebuild       Clean and rebuild all targets.'
	@echo "\t"'bin           Build binaries.'
	@echo "\t"'dep           Generate dependency files.'
	@echo "\t"'lib           Create libraries.'
	@echo "\t"'obj           Compile object files.'
	@echo "\t"'run, r        Build and run main binary.'
	@echo "\t"'test, t       Compile and run tests.'
	@echo
	@echo "\t"'clean         Clean all created files.'
	@echo "\t"'binclean      Clean built binaries.'
	@echo "\t"'depclean      Clean generated dependencies.'
	@echo "\t"'libclean      Clean built libraries.'
	@echo "\t"'objclean      Clean compiled objects.'
	@echo
	@echo "\t"'install       Install build targets.'
	@echo "\t"'uninstall     Uninstall build targets.'
	@echo
	@echo "\t"'check, c      Check sources.'
	@echo "\t"'dist          Create distribution tarball.'
	@echo "\t"'fix           Fix sources.'
	@echo "\t"'fmt           Format sources.'
	@echo "\t"'tag           Generate tag files.'
	@echo
	@echo "\t"'config        Print configuration.'
	@echo "\t"'help          Print this message.'
	@echo "\t"'info          Print build information.'

# Info target
.PHONY: info
info: about
ifneq ($(BINNAMES),)
	@echo
	@echo 'BINARIES:'
	@$(foreach SBIN,$(BINNAMES),echo "\t"'$(SBIN)';)
endif
ifneq ($(LIBNAMES),)
	@echo
	@echo 'LIBRARIES:'
	@$(foreach SLIB,$(LIBNAMES),echo "\t"'$(SLIB)';)
endif
ifneq ($(TESTNAMES),)
	@echo
	@echo 'TESTS:'
	@$(foreach TEST,$(TESTNAMES),echo "\t"'$(TEST)';)
endif
ifneq ($(INSTALL),)
	@echo
	@echo 'INSTALL:'
	@$(foreach TARGET,$(INSTALL),echo "\t"'$(TARGET)';)
endif
# }}}


# --------------------------------
#              Extras
# --------------------------------

# {{{
# Search path
vpath %$(.c)  $(SRC) $(SBIN) $(SLIB) $(TEST)
vpath %$(.cc) $(SRC) $(SBIN) $(SLIB) $(TEST)

# Special variables
PERCENT := %

# Special targets
.PHONY: FORCE
FORCE: # force implicit pattern rules

.DELETE_ON_ERROR: # delete targets on error

.SECONDARY: # do not remove secondary files

.SUFFIXES: # delete the default suffixes

# Includes
ifneq ($(MAKECMDGOALS),clean)
include $(wildcard $(DEPS))
endif
# }}}

# vim:fdl=0:fdm=marker:
