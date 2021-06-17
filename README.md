# cake

<p align="center">
  <img width="100" height="100" src="./doc/cake.svg"/>
</p>

<p align="center">
  <q>
    Qu'ils mangent de la brioche ~ Let them eat cake.
  </q>
  &mdash;
  <i>
    a great princess
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
    - [src/](#src)
      - [src/bin/](#src/bin)
      - [src/lib/](#src/lib)
    - [test/](#test)
  - [Build Configurations](#build-configurations)
  - [Targets](#targets)
    - [Default Goal](#default-goal)
    - [Basic Goals](#basic-goals)
    - [Build Goals](#build-goals)
    - [Install Goals](#install-goals)
    - [Source Goals](#source-goals)
    - [Echo Goals](#echo-goals)
  - [Customization](#customization)
    - [Package](#package)
    - [Build](#build)
    - [Compilers](#compilers)
    - [Directories](#directories)
    - [Extensions](#extensions)
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
├── src
│   ├── lib
│   │   └── foo
│   │       ├── bar.c
│   │       ├── baz.c
│   │       └── foo.cpp
│   └── main.cpp
└── test
    └── test_foo.cpp
```

#### `Cake.mk`

See [customization](#customization) with `Cake.mk` below.

#### `include/`

All headers must use the `*.h `extension (unless otherwise [customized](#extensions)), and should be placed within the `include/` directory.
If they are to be included as a part of a library, it is good practice to further place them within the library's subdirectory.
However, this is not strictly enforced.

#### `src/`

All source files must use either the `*.c` or `*.cpp` extensions (unless otherwise [customized](#extensions)).

In order to differentiate between binaries and libraries, Cake provides two additional subdirectories for your source files; `src/bin/` and `src/lib/`.
All other "assorted" source files not placed in these designated subdirectories will still be compiled to objects which are linked against binaries.
(Note that libraries are intended to compile standalone, and as a result are not linked against these source objects.)

Lastly, the special file(s) `src/main.c` or `src/main.cpp` will be compiled into a binary sharing the name of the package.

##### `src/bin/`

The `src/bin/` directory is strictly for compiling objects to binaries.
Within `src/bin/`, source files can be nested as desired, however, only top-level source files could be built and run as a target.

Cake does not limit the amount of binaries that can be produced by a project.

For example, to compile and run the executable `main`, the source file `src/main.{c,cpp}` should exist.
This can be built and run as a target with `make main`, providing command line arguments through the `ARGS` environment variable.

##### `src/lib/`

The `src/lib/` directory is strictly for compiling libraries.
As such, any source files **must** be placed within a library subdirectory.

Cake does not limit the amount of libraries that can be produced by a project.

For example, to compile the library `foo`, any source files should be placed in `lib/foo` (with headers in `include/foo`).
These will ultimately be compiled both statically and dynamically to `libfoo.a` and `libfoo.so` respectively.

#### `test/`

The `test/` directory is for any writing tests.

Any source files placed within `test/` will be compiled to binaries, and linked against all objects and libraries.
To compile and run all tests, use the `test` target with `make test`.

After running a test, the result is printed to the console as either `done` on success, or `failed` on failure.
(Results are determined by the exit code, with any non-zero indiciating a failure.)

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

#### Basic Goals

##### Default Goal

- `all`: alias for `build`

##### Alternate Builds Configurations

- `debug`: run the default goal using the debug configuration
- `release`: run the default goal using the release configuration

#### Build Goals

- `build`: build all targets; `bin`, `dep`, `lib`, `obj`
- `rebuild`: clean and rebuild all targets; directly implies `clean`, `build`
- `bin`: build binaries; indirectly implies `dep`, `obj`, static `lib`s
- `dep`: generate dependency files
- `lib`: create both static and dynamic libraries; indirectly implies `dep`, `obj`
- `obj`: compile object files; indirectly implies `dep`
- `run`: build and run main binary
- `test`: compile and run tests; indirectly implies `dep`, `obj`, static `lib`s

#### Clean Goals

- `clean`: remove all files created by Cake; removes `bin/`, `lib/`, and `build/` directories
- `binclean`: remove binaries build by Cake; removes  `bin/` and `build/bin/` directories
- `depclean`: remove dependencies generated by Cake; removes `build/dep/` directory
- `libclean`: remove libraries build by Cake; removes  `lib/` and `build/lib/` directories
- `objclean`: remove objects compiled by Cake; removes `build/obj/` directory

#### Install Goals

- `install`: install build targets (must have write permissions for `$(LOCAL)`)
- `uninstall`: uninstall build targets (must have write permissions for `$(LOCAL)`)

#### Source Goals

- `check`: check sources (default: `clang-tidy`)
- `dist`: create distribution tarball (placed in `build/`)
- `fix`: fix sources (default: `clang-tidy`)
- `fmt`: format sources (default: `clang-format`)
- `tag`: generate tag files (placed in `build/`, default: `ctags`)

#### Echo Goals

- `conifig`: print configuration
- `help`: print help message
- `info`: print build information

### Customization

In addition to its other powerful features, Cake aims to be highly customizable.
To that end, it provides the optional file `Cake.mk` which is parsed before each invocation.

The following options can be overridden either on the command line, through environment variables, or in the `Cake.mk` configuration file:

#### Package

- `NAME`: name of package; may not contain spaces (default: name of root directory)
- `VERSION`: version of package (default: Unix timestamp)
- `AUTHOR`: stores author information; used in `make about`

#### Build

- `CONFIG`: [build configuration](#build-configurations) to use; has priority (default: `DEFAULT`)
- `DEFAULT`: alternate way to specify default build configuration (default: `1`)
- `DEBUG`: alternate way to specify debug build configuration (default: not set)
- `RELEASE`: alternate way to specify release build configuration (default: not set)

#### Compilers

- `CC`: compiler for C (default: `cc`)
- `CXX`: compiler for C++ (default: `c++`)

#### Directories

- `BIN`: binaries directory (default: `src/bin/`)
- `BUILD`: build output directory (default: `build/`)
- `INCLUDE`: headers directory (default: `include/`)
- `LIB`: libraries directory (default: `src/lib/`)
- `LOCAL`: installation directory (default:`usr/local/`)
- `ROOT`: root directory of project; change with caution (default: `./`)
- `SRC`: sources directory (default: `src/`)
- `TEST`: tests directory (default: `test/`)

#### Extensions

- `.a`: file extension for static libraries (default: `.a`)
- `.c`: file extension for C sources (default: `.c`)
- `.cc`: file extension for C++ sources (default: `.cpp`)
- `.d`: file extension for dependencies (default: `.d`)
- `.h`: file extension for headers (default: `.h`)
- `.o`: file extension for objects (default: `.o`)
- `.so`: file extension for dynamic libraries (default: `.so`)

#### Files

- `TAGFILE`: output tagfile (default: `build/tags`)
- `TARFILE`: tarfile root name; formatted as `$(BUILD)/$(TARFILE).tar.gz` (default: `$(NAME)-$(VERSION)`)
- `DISTFILES`: list of files to include in distribution tarball (default: files tracked in git)

#### Flags

- `CFLAGS`: options for C compiler (default: `-Wall -g -std=c18`)
- `CPPFLAGS`: options for C/C++ preprocessor (default: `-I/include`)
- `CXXFLAGS`: options for C++ compiler (default: `-Wall -g -std=c++17`)
- `LDFLAGS`: options for linker
- `LDLIBS`: libraries for linker

## License

This project is licensed under the terms of the MIT license.
