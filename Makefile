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
LIBRARIES = $(addprefix -L,$(LIB))
LIBLINKS  = $(addprefix -l,$(notdir $(LIDS)))

# Sources
HEADERS    := $(shell find -L $(ROOT) -name "*.h")
CSOURCES   := $(shell find -L $(ROOT) -name "*.c")
CXXSOURCES := $(shell find -L $(ROOT) -name "*.cpp")
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
LIDS   := $(sort $(patsubst %/,%,$(dir $(LIBS))))
LIDARS  = $(LIDS:$(LIB)/%=$(LID)/lib%.a)
LIDSOS  = $(LIDS:$(LIB)/%=$(LID)/lib%.so)
# Object targets (filtered)
CLIBOS   = $(CLIBS:$(LIB)/%.c=$(OBJ)/%.o)
CXXLIBOS = $(CXXLIBS:$(LIB)/%.cpp=$(OBJ)/%.o)
CSRCOS   = $(CSRCS:$(SRC)/%.c=$(OBJ)/%.o)
CXXSRCOS = $(CXXSRCS:$(SRC)/%.cpp=$(OBJ)/%.o)
CTSTOS   = $(CTSTS:$(ROOT)/%.c=$(OBJ)/%.o)
CXXTSTOS = $(CXXTSTS:$(ROOT)/%.cpp=$(OBJ)/%.o)
# Object targets (combined)
LIBOS = $(CLIBOS) $(CXXLIBOS)
SRCOS = $(CSRCOS) $(CXXSRCOS)
TSTOS = $(CTSTOS) $(CXXTSTOS)
OBJS  = $(LIBOS) $(SRCOS)
# Primary targets
BINS  = $(SRCOS:$(OBJ)/%.o=$(BIN)/%)
DEPS  = $(OBJS:$(OBJ)/%.o=$(DEP)/%.d)
TESTS = $(TSTOS:$(OBJ)/%.o=$(BIN)/%)
# Secondary targets
TAGFILE   ?= $(BUILD)/tags
TARFILE   ?= $(NAME)-$(VERSION)
DISTFILES ?= $(or $(shell [ -d $(ROOT)/.git ] && git ls-files), \
                  $(MAKEFILE_LIST) $(HEADERS) $(SOURCES))

# Commands
CHECK = clang-tidy
FIX   = clang-tidy --fix-errors
FMT   = clang-format --verbose -i
LN    = ln -sf
MKDIR = mkdir -p
RM    = rm -rf
TAGS  = ctags
TAR   = tar
# Compiler
AR  = ar
CC  = cc
CXX = c++
# Flags
ARFLAGS   = crs
CFLAGS   ?= -Wall -g -std=c18
CPPFLAGS += $(INCLUDES)
CXXFLAGS ?= -Wall -g -std=c++17
DEPFLAGS  = -MM -MF $@ -MT $(OBJ)/$*.o
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
#           Build Rules
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
#          Primary Rules
# --------------------------------

# Build executables
.PHONY: bin
bin: $(BINS)

# Link target executables
$(BIN)/%: $(OBJ)/%.o $(LIDARS) | $(BINLINK)/%
	@$(MKDIR) $(@D)
	$(LINK.cc) -o $@ $^ $(LDLIBS)

$(BINLINK)/%: FORCE
	@$(MKDIR) $(@D)
	@$(LN) $(shell realpath -m $(BIN)/$* --relative-to $(@D)) $@

# Run target executable
%: $(BIN)/% FORCE ; @$< $(ARGS)

# Generate dependency files
.PHONY: dep
dep: $(DEPS)

$(DEP)/%.d: %.c
	@$(MKDIR) $(@D)
	@$(LINK.c) $(DEPFLAGS) $<

$(DEP)/%.d: %.cpp
	@$(MKDIR) $(@D)
	@$(LINK.cc) $(DEPFLAGS) $<

# Create libraries
.PHONY: lib
lib: $(LIDARS) $(LIDSOS)

$(LIBOS): CPPFLAGS += -fPIC # compile libraries with PIC

# Combine library archives
.SECONDEXPANSION:
$(LID)/lib%.a: $$(filter $(OBJ)/%/$$(PERCENT),$(OBJS)) | $(LIB)/%/*
	@$(MKDIR) $(@D)
	$(AR) $(ARFLAGS) $@ $^

# Link library shared objects
.SECONDEXPANSION:
$(LID)/lib%.so: LDFLAGS += -shared
$(LID)/lib%.so: $$(filter $(OBJ)/%/$$(PERCENT),$(OBJS)) | $(LIB)/%/*
	@$(MKDIR) $(@D)
	$(LINK.cc) -o $@ $^ $(LDLIBS)

# Create target library
%: $(LID)/lib%.a $(LID)/lib%.so FORCE ;

# Compile object files
.PHONY: obj
obj: $(OBJS)

$(OBJ)/%.o: %.c | $(DEP)/%.d
	@$(MKDIR) $(@D)
	$(COMPILE.c) -o $@ $<

$(OBJ)/%.o: %.cpp | $(DEP)/%.d
	@$(MKDIR) $(@D)
	$(COMPILE.cc) -o $@ $<

# Compile and run tests
.PHONY: test
test: $(TESTS)
	$(foreach TEST,$^,$(TEST);)


# --------------------------------
#         Secondary Rules
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
#              Extras
# --------------------------------

# Search path
vpath %.c   $(LIB) $(ROOT) $(SRC) $(TEST)
vpath %.cpp $(LIB) $(ROOT) $(SRC) $(TEST)

# Special variables
PERCENT := %

# Special targets
.PHONY: FORCE
FORCE: # force implicit pattern rules

.PRECIOUS: \
	$(BIN)/% \
	$(BINLINK)/% \
	$(DEP)/%.d \
	$(OBJ)/%.o \

.SUFFIXES: # delete the default suffixes

# Includes
ifneq ($(MAKECMDGOALS),clean)
include $(wildcard $(DEPS))
endif
