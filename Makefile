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

# Root directory
ROOT ?= .
# Makefiles
MAKEFILE = $(firstword $(MAKEFILE_LIST))
CAKEFILE = $(ROOT)/Cake.mk

# User configuration
-include $(CAKEFILE)

# Package
NAME    ?= $(shell basename "$(PWD)")
VERSION ?= $(shell date +%s)


# --------------------------------
#            Variables
# --------------------------------

# -- Directories --
# Input directories
INCLUDE ?= $(ROOT)/include
SRC     ?= $(ROOT)/src
TEST    ?= $(ROOT)/test
# Source directories
BIN = $(SRC)/bin
LIB = $(SRC)/lib
# Build directories
BUILD ?= $(ROOT)/build
BBIN   = $(BUILD)/bin
BLIB   = $(BUILD)/lib
DEP    = $(BUILD)/dep
OBJ    = $(BUILD)/obj
# Linked build directories
BINLINK := $(BUILD)/../bin
LIBLINK := $(BUILD)/../lib
# Install directories
LOCAL ?= /usr/local
IROOT  = $(LOCAL)/$(NAME)
IBIN   = $(IROOT)/bin
ILIB   = $(IROOT)/lib
LBIN   = $(LOCAL)/bin
LLIB   = $(LOCAL)/lib

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
# Prerequisites (filtered)
CBINS   := $(filter $(BIN)/%,$(CSOURCES))
CXXBINS := $(filter $(BIN)/%,$(CXXSOURCES))
CLIBS   := $(filter $(LIB)/%,$(CSOURCES))
CXXLIBS := $(filter $(LIB)/%,$(CXXSOURCES))
CTSTS   := $(filter $(TEST)/%,$(CSOURCES))
CXXTSTS := $(filter $(TEST)/%,$(CXXSOURCES))
# Prerequisites (combined)
SBINS := $(CBINS) $(CXXBINS)
SLIBS := $(CLIBS) $(CXXLIBS)
STSTS := $(CTSTS) $(CXXTSTS)
# Object targets (filtered)
CBINOS   = $(CBINS:$(BIN)/%$(.c)=$(OBJ)/%$(.o))
CXXBINOS = $(CXXBINS:$(BIN)/%$(.cc)=$(OBJ)/%$(.o))
CLIBOS   = $(CLIBS:$(LIB)/%$(.c)=$(OBJ)/%$(.o))
CXXLIBOS = $(CXXLIBS:$(LIB)/%$(.cc)=$(OBJ)/%$(.o))
CTSTOS   = $(CTSTS:$(ROOT)/%$(.c)=$(OBJ)/%$(.o))
CXXTSTOS = $(CXXTSTS:$(ROOT)/%$(.cc)=$(OBJ)/%$(.o))
# Object targets (combined)
BINOBJS = $(CBINOS) $(CXXBINOS)
LIBOBJS = $(CLIBOS) $(CXXLIBOS)
TSTOBJS = $(CTSTOS) $(CXXTSTOS)
OBJS    = $(BINOBJS) $(LIBOBJS)
# Binary targets
BINS     = $(BINOBJS:$(OBJ)/%$(.o)=$(BBIN)/%)
BINNAMES = $(BINS:$(BBIN)/%=%)
# Dependency targets
DEPS = $(OBJS:$(OBJ)/%$(.o)=$(DEP)/%$(.d))
# Library targets
LIBDS    := $(sort $(patsubst %/,%,$(dir $(SLIBS))))
LIBDS    := $(filter-out $(addsuffix /%,$(LIBDS)),$(LIBDS))
LIBARS    = $(LIBDS:$(LIB)/%=$(BLIB)/lib%$(.a))
LIBSOS    = $(LIBDS:$(LIB)/%=$(BLIB)/lib%$(.so))
LIBS      = $(LIBARS) $(LIBSOS)
LIBNAMES  = $(LIBDS:$(LIB)/%=%)
# Test targets
TSTS  = $(TSTOBJS:$(OBJ)/%$(.o)=$(BBIN)/%)
TESTS = $(TSTS:$(BBIN)/%=%)
# Install targets
LBINS = $(BINS:$(BBIN)/%=$(LBIN)/%)
LLIBS = $(LIBS:$(BLIB)/%=$(LLIB)/%)
# Source targets
TAGFILE   ?= $(BUILD)/tags
TARFILE   ?= $(NAME)-$(VERSION)
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
CXXFLAGS ?= -Wall -g -std=c++17
DEPFLAGS  = -MM -MF $@ -MT $(OBJ)/$*$(.o)
LDFLAGS  +=
LDLIBS   +=
TARFLAGS  = -zchvf
# Flag partials
INCLUDES  = $(addprefix -I,$(INCLUDE))
LIBRARIES = $(addprefix -L,$(BLIB))
LIBFLAGS  = $(addprefix -l,$(LIBNAMES))

# Conditional flags
ifneq ($(LIBNAMES),)
$(BINS) $(TSTS): LDFLAGS += $(LIBRARIES) # libraries should be linked...
$(BINS) $(TSTS): LDLIBS  += $(LIBFLAGS)  # ...when building an executable
endif

# Build settings
MODES   = DEBUG DEFAULT RELEASE
CONFIG ?= DEFAULT
ifneq ($(filter $(CONFIG),$(MODES)),)
$(CONFIG) = 1
else
$(error unknown build: `$(CONFIG)`)
endif

ifdef DEBUG        # debug build
BUILD    := $(BUILD)/debug
CPPFLAGS += -O0 -g3 -DDEBUG
else ifdef RELEASE # release build
BUILD    := $(BUILD)/release
CPPFLAGS += -O3 -g0 -DNDEBUG
endif


# --------------------------------
#           Basic Goals
# --------------------------------

# Explicitly set default goal
.DEFAULT_GOAL := all

# Build all goals
.PHONY: all
all: bin dep lib obj

# Clean build directory
.PHONY: clean
clean:
	@$(RM) -v $(BINLINK) $(LIBLINK) $(BUILD)

# Make alternate builds
.PHONY: debug
debug: export DEBUG = 1
debug:
	@$(MAKE) all

.PHONY: release
release: export RELEASE = 1
release:
	@$(MAKE) all


# --------------------------------
#           Build Goals
# --------------------------------

# Build executables
.PHONY: bin
bin: $(BINS)

# Create executable symlinks
$(BINS): $(BBIN)/%: | $(BINLINK)/%

$(BINLINK)/%: FORCE
	@$(MKDIR) $(@D)
	@$(LN) $(shell realpath -m $(BBIN)/$* --relative-to $(@D)) $@

# Link target executables
$(BBIN)/%: $(OBJ)/%$(.o) $(LIBARS)
	@$(MKDIR) $(@D)
	$(LINK.cc) -o $@ $< $(LDLIBS)

# Run target executable
$(BINNAMES): %: $(BBIN)/% FORCE ; @$< $(ARGS)

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

# Create libraries
.PHONY: lib
lib: $(LIBS)

$(LIBOBJS): CPPFLAGS += -fPIC # compile libraries with PIC

# Create library symlinks
$(LIBS): $(BLIB)/%: | $(LIBLINK)/%

$(LIBLINK)/%: FORCE
	@$(MKDIR) $(@D)
	@$(LN) $(shell realpath -m $(BLIB)/$* --relative-to $(@D)) $@

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

# Create target library
$(LIBNAMES): %: $(BLIB)/lib%$(.a) $(BLIB)/lib%$(.so) FORCE

# Compile object files
.PHONY: obj
obj: $(OBJS)

$(OBJ)/%$(.o): %$(.c) | $(DEP)/%$(.d)
	@$(MKDIR) $(@D)
	$(COMPILE.c) -o $@ $<

$(OBJ)/%$(.o): %$(.cc) | $(DEP)/%$(.d)
	@$(MKDIR) $(@D)
	$(COMPILE.cc) -o $@ $<

# Compile and run tests
.PHONY: test
test: | $(filter-out test,$(MAKECMDGOALS)) # always run tests last
	@$(foreach TEST,$(TESTS),$(MAKE) $(TEST);)

.PHONY: $(TESTS)
$(TESTS): %: $(BBIN)/%
	@echo -n Running $(@F)...
	@$< &> $(DEVNULL)      \
		&& echo done   \
		|| echo failed


# --------------------------------
#          Install Goals
# --------------------------------

$(shell test -w $(LOCAL)) # test for write permissions
ifeq ($(.SHELLSTATUS),)
.SHELLSTATUS = $(shell test -w $(LOCAL); echo $$?)
endif

# Install build targets
.PHONY: install
install: INSTALL = $(IROOT) $(LBINS) $(LLIBS)
ifneq ($(.SHELLSTATUS), 0)
install:
	$(warning The following files will be created:)
	$(foreach FILE,$(INSTALL),$(warning - $(FILE)))
	$(error Insufficient permissions for `$(LOCAL)`)
else
install: $(LBINS) $(LLIBS)
endif

$(IROOT)/%: $(BUILD)/%
	@$(MKDIR) $(@D)
	@$(CP) -vi $< $@

$(LOCAL)/%: $(IROOT)/%
	@$(MKDIR) $(@D)
	@$(LN) -vi $(shell realpath -m $< --relative-to $(@D)) $@

# Uninstall build targets
.PHONY: uninstall
uninstall: UNINSTALL = $(wildcard $(IROOT) $(LBINS) $(LLIBS))
uninstall:
ifneq ($(.SHELLSTATUS), 0)
	$(if $(UNINSTALL),                                       \
		$(warning The following files will be removed:), \
		$(warning Nothing to uninstall.)                 \
	)
	$(foreach FILE,$(UNINSTALL),$(warning - $(FILE)))
	$(error Insufficient permissions for `$(LOCAL)`)
else
	@$(RM) -v $(UNINSTALL)
endif


# --------------------------------
#           Source Goals
# --------------------------------

# Check sources
.PHONY: check
check:
	@$(CHECK) $(SOURCES) -- $(INCLUDES)

# Create distribution tar file
.PHONY: dist
dist: $(BUILD)/$(TARFILE).tar.gz

$(BUILD)/$(TARFILE).tar.gz: $(TARFILE)
	@$(MKDIR) $(@D)
	@$(TAR) $(TARFLAGS) $@ $<
	@$(RM) $<

$(TARFILE): $(DISTFILES:%=$(TARFILE)/%)

$(TARFILE)/%: %
	@$(MKDIR) $(@D)
	@$(LN) $(shell realpath -m $< --relative-to $(@D)) $@

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


# --------------------------------
#            Echo Goals
# --------------------------------

# Print about
.PHONY: about
about:
ifdef NAME
	@echo "$(NAME)" "$(VERSION)"
endif
ifdef AUTHOR
	@echo "$(AUTHOR)"
endif
ifdef DESCRIPTION
	@echo "$(DESCRIPTION)"
endif

# Help target
.PHONY: help
help: about
	@echo
	@echo "USAGE:"
	@echo "\t""make [TARGET]"
	@echo
	@echo "TARGETS:"
	@echo "\t""all           Build all goals. (default"
	@echo "\t""clean         Clean build directory."
	@echo "\t""debug         Make debug build."
	@echo "\t""release       Make release build."
	@echo
	@echo "\t""bin           Build executables."
	@echo "\t""dep           Generate dependency files."
	@echo "\t""lib           Create libraries."
	@echo "\t""obj           Compile object files."
	@echo "\t""test          Compile and run tests."
	@echo
	@echo "\t""install       Install build targets."
	@echo "\t""uninstall     Uninstall build targets."
	@echo
	@echo "\t""check         Check sources."
	@echo "\t""dist          Create distribution tar file."
	@echo "\t""fix           Fix sources."
	@echo "\t""fmt           Format sources."
	@echo "\t""tag           Generate tag files."
	@echo
	@echo "\t""help          Print this message."
	@echo "\t""info          Print build information."
	@echo

# Info target
.PHONY: info
info: about
	@echo
ifneq ($(BINNAMES),)
	@echo "EXECUTABLES:"
	@$(foreach BIN,$(BINNAMES),echo "\t""$(BIN)";)
	@echo
endif
ifneq ($(LIBNAMES),)
	@echo "LIBRARIES:"
	@$(foreach LIB,$(LIBNAMES),echo "\t""$(LIB)";)
	@echo
endif
ifneq ($(TESTS),)
	@echo "TESTS:"
	@$(foreach TEST,$(TESTS),echo "\t""$(TEST)";)
	@echo
endif


# --------------------------------
#              Extras
# --------------------------------

# Search path
vpath %$(.c)  $(BIN) $(LIB) $(TEST)
vpath %$(.cc) $(BIN) $(LIB) $(TEST)

# Special variables
PERCENT := %

# Special targets
.PHONY: FORCE
FORCE: # force implicit pattern rules

.SECONDARY: # do not remove secondary files

.SUFFIXES: # delete the default suffixes

# Includes
ifneq ($(MAKECMDGOALS),clean)
include $(wildcard $(DEPS))
endif


# --------------------------------
#             Asserts
# --------------------------------

ifeq ($(.c),$(.cc))
$(error Cannot use same extension for C and C++ sources)
endif

ASSERT_LIBSRCS := $(wildcard $(LIB)/*$(.c) $(LIB)/*$(.cc))
ifneq ($(ASSERT_LIBSRCS),)
$(error Invalid placement of library source files: $(ASSERT_LIBSRCS))
endif
