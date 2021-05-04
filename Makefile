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

# Include user config
-include $(CAKEFILE)

# Package
NAME    ?= $(shell basename "$(PWD)")
VERSION ?= $(shell date +%s)


# --------------------------------
#            Variables
# --------------------------------

# Input directories
INCLUDE ?= $(ROOT)/include
LIB     ?= $(ROOT)/lib
SRC     ?= $(ROOT)/src
TEST    ?= $(ROOT)/test
# Build directories
BUILD ?= $(ROOT)/build
# Build subdirectories (absolute)
BINLINK := $(BUILD)/../bin
# Build subdirectories (relative)
BIN = $(BUILD)/bin
DEP = $(BUILD)/dep
LID = $(BUILD)/lib
OBJ = $(BUILD)/obj
# Search directories
INCLUDES  = $(addprefix -I,$(INCLUDE))
LIBRARIES = $(addprefix -L,$(LID))
LIBLINKS  = $(addprefix -l,$(notdir $(LIDS)))
# Install directories
LOCAL ?= /usr/local
IROOT  = $(LOCAL)/$(NAME)
IBIN   = $(IROOT)/bin
ILID   = $(IROOT)/lib
LBIN   = $(LOCAL)/bin
LLID   = $(LOCAL)/lib

# Extensions
.a  ?= .a
.c  ?= .c
.cc ?= .cpp
.d  ?= .d
.h  ?= .h
.o  ?= .o
.so ?= .so

# Sources
HEADERS    := $(shell find -L $(ROOT) -name "*$(.h)")
CSOURCES   := $(shell find -L $(ROOT) -name "*$(.c)")
CXXSOURCES := $(shell find -L $(ROOT) -name "*$(.cc)")
SOURCES     = $(CSOURCES) $(CXXSOURCES)
# Prerequisites (filtered)
CLIBS   := $(filter $(LIB)/%,$(CSOURCES))
CXXLIBS := $(filter $(LIB)/%,$(CXXSOURCES))
CSRCS   := $(filter $(SRC)/%,$(CSOURCES))
CXXSRCS := $(filter $(SRC)/%,$(CXXSOURCES))
CTSTS   := $(filter $(TEST)/%,$(CSOURCES))
CXXTSTS := $(filter $(TEST)/%,$(CXXSOURCES))
# Prerequisites (combined)
LIBS := $(CLIBS) $(CXXLIBS)
SRCS := $(CSRCS) $(CXXSRCS)
TSTS := $(CTSTS) $(CXXTSTS)
# Library targets
LIDS    := $(sort $(patsubst %/,%,$(dir $(LIBS))))
LIDS    := $(filter-out $(addsuffix /%,$(LIDS)),$(LIDS))
LIDARS   = $(LIDS:$(LIB)/%=$(LID)/lib%$(.a))
LIDSOS   = $(LIDS:$(LIB)/%=$(LID)/lib%$(.so))
LIDOBJS  = $(LIDARS) $(LIDSOS)
# Object targets (filtered)
CLIBOS   = $(CLIBS:$(LIB)/%$(.c)=$(OBJ)/%$(.o))
CXXLIBOS = $(CXXLIBS:$(LIB)/%$(.cc)=$(OBJ)/%$(.o))
CSRCOS   = $(CSRCS:$(SRC)/%$(.c)=$(OBJ)/%$(.o))
CXXSRCOS = $(CXXSRCS:$(SRC)/%$(.cc)=$(OBJ)/%$(.o))
CTSTOS   = $(CTSTS:$(ROOT)/%$(.c)=$(OBJ)/%$(.o))
CXXTSTOS = $(CXXTSTS:$(ROOT)/%$(.cc)=$(OBJ)/%$(.o))
# Object targets (combined)
LIBOS = $(CLIBOS) $(CXXLIBOS)
SRCOS = $(CSRCOS) $(CXXSRCOS)
TSTOS = $(CTSTOS) $(CXXTSTOS)
OBJS  = $(LIBOS) $(SRCOS)
# Build targets
BINS  = $(SRCOS:$(OBJ)/%$(.o)=$(BIN)/%)
DEPS  = $(OBJS:$(OBJ)/%$(.o)=$(DEP)/%$(.d))
TESTS = $(TSTOS:$(OBJ)/%$(.o)=$(BIN)/%)
# Install targets
LBINS = $(BINS:$(BIN)/%=$(LBIN)/%)
LLIDS = $(LIDOBJS:$(LID)/%=$(LLID)/%)
# Source targets
TAGFILE   ?= $(BUILD)/tags
TARFILE   ?= $(NAME)-$(VERSION)
DISTFILES ?= $(or $(shell [ -d $(ROOT)/.git ] && git ls-files), \
                  $(MAKEFILE_LIST) $(HEADERS) $(SOURCES))

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
# Flags
ARFLAGS   = crs
CFLAGS   ?= -Wall -g -std=c18
CPPFLAGS += $(INCLUDES)
CXXFLAGS ?= -Wall -g -std=c++17
DEPFLAGS  = -MM -MF $@ -MT $(OBJ)/$*$(.o)
LDFLAGS  +=
LDLIBS   +=
TARFLAGS  = -zchvf

# Alternate build settings
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
all: bin dep lib obj $(TESTS)

# Clean build directory
.PHONY: clean
clean:
	@$(RM) -v $(BINLINK) $(BUILD)

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

$(BINS): LDFLAGS += $(LIBRARIES) # libraries should be linked...
$(BINS): LDLIBS  += $(LIBLINKS)  # ...when building an executable

# Link target executables
$(BIN)/%: $(OBJ)/%$(.o) $(LIDARS) | $(BINLINK)/%
	@$(MKDIR) $(@D)
	$(LINK.cc) -o $@ $< $(LDLIBS)

$(BINLINK)/%: FORCE
	@$(MKDIR) $(@D)
	@$(LN) $(shell realpath -m $(BIN)/$* --relative-to $(@D)) $@

# Run target executable
%: $(BIN)/% FORCE ; @$< $(ARGS)

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
lib: $(LIDARS) $(LIDSOS)

$(LIBOS): CPPFLAGS += -fPIC # compile libraries with PIC

# Combine library archives
.SECONDEXPANSION:
$(LID)/lib%$(.a): $$(filter $(OBJ)/%/$$(PERCENT),$(OBJS)) | $(LIB)/%/*
	@$(MKDIR) $(@D)
	$(AR) $(ARFLAGS) $@ $^

# Link library shared objects
.SECONDEXPANSION:
$(LID)/lib%$(.so): LDFLAGS += -shared
$(LID)/lib%$(.so): $$(filter $(OBJ)/%/$$(PERCENT),$(OBJS)) | $(LIB)/%/*
	@$(MKDIR) $(@D)
	$(LINK.cc) -o $@ $^ $(LDLIBS)

# Create target library
%: $(LID)/lib%$(.a) $(LID)/lib%$(.so) FORCE ;

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
test: $(TESTS)
	$(foreach TEST,$^,$(TEST);)


# --------------------------------
#          Install Goals
# --------------------------------

$(shell test -w $(LOCAL)) # test for write permissions
ifeq ($(.SHELLSTATUS),)
.SHELLSTATUS = $(shell test -w $(LOCAL); echo $$?)
endif

# Install build targets
.PHONY: install
install: INSTALL = $(IROOT) $(LBINS) $(LLIDS)
ifneq ($(.SHELLSTATUS), 0)
install:
	$(warning The following files will be created:)
	$(foreach FILE,$(INSTALL),$(warning - $(FILE)))
	$(error Insufficient permissions for `$(LOCAL)`)
else
install: $(LBINS) $(LLIDS)
endif

$(IROOT)/%: $(BUILD)/%
	@$(MKDIR) $(@D)
	@$(CP) -vi $< $@

$(LOCAL)/%: $(IROOT)/%
	@$(MKDIR) $(@D)
	@$(LN) -vi $(shell realpath -m $< --relative-to $(@D)) $@

# Uninstall build targets
.PHONY: uninstall
uninstall: UNINSTALL = $(wildcard $(IROOT) $(LBINS) $(LLIDS))
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

# Print header
.PHONY: header
header:
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
help: header
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
info: header
	@echo
ifneq ($(BINS),)
	@echo "EXECUTABLES:"
	@$(foreach EXE,$(BINS),echo "\t""$(EXE:$(BIN)/%=%)";)
	@echo
endif
ifneq ($(LIDS),)
	@echo "LIBRARIES:"
	@$(foreach LID,$(LIDS),echo "\t""$(LID:$(LIB)/%=%)";)
	@echo
endif


# --------------------------------
#              Extras
# --------------------------------

# Search path
vpath %$(.c)  $(LIB) $(ROOT) $(SRC) $(TEST)
vpath %$(.cc) $(LIB) $(ROOT) $(SRC) $(TEST)

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
