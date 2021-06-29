// File:        foo.cpp
// Author:      Zakhary Kaplan <https://zakharykaplan.ca>
// Created:     05 Jan 2021
// SPDX-License-Identifier: MIT

#include "foo/foo.h"

#include <cstdlib>
#include <iostream>

extern "C" {
#include "foo/bar.h"
#include "foo/baz.h"
}

void foo() {
    std::cout << bar() << std::endl;
    std::exit(baz());
}
