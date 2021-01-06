# cake

<p align="center">
  <img width="100" height="100" src="./doc/birthday-cake-cake-svgrepo-com.svg"/>
</p>

<p align="center">
  <q>
    Qu'ils mangent de la brioche ~ Let them eat cake.
  </q>
  <i>
    &mdash; a great princess
  </i>
</p>

---

Cake is a C/C++ Makefile-based build system, aimed at providing quick and easy development.
It provides all the `make` targets you know and love, with the added bonus of being completely agnostic to the project itself.

## Table of Contents

- [Usage](#usage)
  - [Installation](#installation)
  - [Dependencies](#dependencies)
    - [Required](#required)
    - [Optional](#optional)
  - [Directory Structure](#directory-structure)
    - [Cake.mk](#cakemk)
    - [include/](#include)
    - [lib/](#lib)
    - [src/](#src)
  - [Build Configurations](#build-configurations)
  - [Targets](#targets)
    - [Default Goal](#default-goal)
    - [Build Goals](#build-goals)
    - [Primary Goals](#primary-goals)
    - [Secondary Goals](#secondary-goals)
  - [Customization](#customization)
    - [Package](#package)
    - [Build](#build)
    - [Directories](#directories)
    - [Files](#files)
    - [Flags](#flags)
- [License](#license)

## Usage

### Installation

Getting started with Cake is as easy as:

```bash
wget https://raw.githubusercontent.com/zakharykaplan/cake/main/Makefile
```

Simply download the [`Makefile`](./Makefile) into your C/C++ project directory and compile away!

### Dependencies

Cake tries to be POSIX compliant as much as possible, as a result, it should run on most Unix/Linux system out of the box.
In most cases, you should already have all dependencies already installed on your system by default, however the full list is as follows:

#### Required

- `ar`: archive utility to create static libraries
- `basename`: basename utility to strip directory and suffix from filenames
- `cc`: C compiler, e.g. `gcc`, `clang`
- `c++`: C++ compiler, e.g. `g++`, `clang++`
- `date`: date utility to get epoch timestamp
- `find`: find utility to search for source files within directory tree
- `make`: this is probably important to have (preferably GNU Make)
- `realpath`: realpath utility to resolve relative paths

#### Optional

- `clang-format`: used for code formatting with `make fmt`
- `clang-tidy`: used for code linting with `make (check|tidy)`
- `git`: used to determine files to tar with `make dist`
- `tar`: used to create a distribution tarball with `make dist`

### Directory Structure

In order to correctly build your project, Cake expects the following directory structure:

```
.
├── Cake.mk
├── Makefile
├── include
│   └── foo
│       ├── bar.h
│       ├── baz.h
│       └── foo.h
├── lib
│   └── foo
│       ├── bar.c
│       ├── baz.c
│       └── foo.cpp
└── src
    └── main.cpp
```

#### `Cake.mk`

See [customization](#customization) with `Cake.mk` below.

#### `include/`

All headers must use the `*.h` extension, and should be placed within the `include` directory.
If they are to be included as a part of a library, it is good practice to place them further within the library's subdirectory.

#### `lib/`

All source files must use either the `*.c` or `*.cpp` extensions.
In order to differentiate between libraries and executables, Cake provides two directories for your source files.
The `lib` directory is strictly for compiling libraries.
As such, any source files **must** be placed within a library subdirectory.

Cake does not limit the amount of libraries that can be produced by a project.

For example, to compile the library `foo`, any source files should be placed in `lib/foo` (with headers in `include/foo`).
These will ultimately be compiled both statically and dynamically to `libfoo.a` and `libfoo.so` respectively.

#### `src/`

All source files must use either the `*.c` or `*.cpp` extensions.
In order to differentiate between libraries and executables, Cake provides two directories for your source files.
The `src` directory is strictly for compiling executables.
Within `src`, source files can be nested as desired, however, only top-level source files could be built and run as a target.

Cake does not limit the amount of executables that can be produced by a project.

For example, to compile and run the executable `main`, the source file `src/main.{c,cpp}` should exist.
This can be built and run as a target with `make main`, providing command line arguments through the `ARGS` environment variable.

### Build Configurations

Cake provides three different build configurations to use when compiling your project:

- `DEFAULT`: use the default build configurations; some optimizations and basic debug information
- `DEBUG`: build with fewer optimizations and maximum debug information
- `RELEASE`: build with more optimizations and without debug information

These can be specified as a [customization](#customization).

### Targets

To start compilation with Cake, often just running `make` will be enough!
Cake automatically parses your project directories to gather source files and targets, and also manages auto-dependency generation through your compiler.

To build specific targets, Cake provides the following Makefile goals:

#### Default Goal

- `all`: build all primary goals; directly implies `bin`, `dep`, `lib`, `obj`, compiling `test`

#### Build Goals

- `clean`: remove all files generated by Cake, including the `bin/` and `build/` directories
- `debug`: run the default goal using the debug configuration
- `release`: run the default goal using the release configuration

#### Primary Goals

- `bin`: build executables; indirectly implies `dep`, `obj`, static `lib`s
- `dep`: generate dependency files
- `lib`: create both static and dynamic libraries; indirectly implies `dep`, `obj`
- `obj`: compile object files; indirectly implies `dep`
- `test`: compile and run tests; indirectly implies `dep`, `obj`, static `lib`s

#### Secondary Goals

- `check`: check all sources (default: `clang-tidy`)
- `dist`: create a distribution tarball (placed in `build/`)
- `fix`: fix all sources (default: `clang-tidy`)
- `fmt`: format all sources (default: `clang-format`)
- `tag`: generate tag files (placed in `build/`, default: `ctags`)

### Customization

In addition to it's other powerful features, Cake aims to be highly customizable.
To that end, it provides the optional file `Cake.mk` which is parsed before each invocation.

The following options can be overridden either on the command line, through environment variables, or in the `Cake.mk` configuration file:

#### Package

- `NAME`: name of package (default: name of root directory)
- `VERSION`: version of package (default: epoch timestamp)
- `AUTHOR`: stores author information; currently unused

#### Build

- `CONFIG`: [build configuration](#build-configurations) to use (default: `DEFAULT`)
- `DEFAULT`: alternate way to specify default build configuration (default: `1`)
- `DEBUG`: alternate way to specify debug build configuration (default: not set)
- `RELEASE`: alternate way to specify release build configuration (default: not set)

#### Directories

- `ROOT`: root directory of project; change with caution
- `BUILD`; build output directory (default: `build/`)
- `INCLUDE`; include directory (default: `include/`)
- `LIB`; libraries directory (default: `lib/`)
- `SRC`; executables directory (default: `src/`)
- `TEST`; tests directory (default: `test/`)

#### Files

- `TAGFILE`: output tagfile (default: `build/tags`)
- `TARFILE`: tarfile root name; formatted as `$(BUILD)/$(TARFILE).tar.gz` (default: `$(NAME)-$(VERSION)`)
- `DISTFILES`: list of files to include in distribution tarball (default: files tracked in git)

#### Flags

- `CFLAGS`: options for C compiler, `cc` (default: `-Wall -g -std=c18`)
- `CXXFLAGS`: options for C++ compiler, `c++` (default: `-Wall -g -std=c++17`)

## License

This project is licensed under the terms of the MIT license.
