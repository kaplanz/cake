// File:        test_foo.cpp
// Author:      Zakhary Kaplan <https://zakharykaplan.ca>
// Created:     13 Jun 2021
// SPDX-License-Identifier: MIT

#include <cassert>
#include <cstring>

extern "C" {
#include "foo/bar.h"
#include "foo/baz.h"
}

void test_bar() {
    assert(!strcmp(bar(), "Hello, world!"));
}

void test_baz() {
    assert(baz() == EXIT_SUCCESS);
}

int main() {
    test_bar();
    test_baz();
}
