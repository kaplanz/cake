//
//  test_foo.cpp
//  Test module for foo library.
//
//  Created by Zakhary Kaplan on 2021-06-13.
//  Copyright © 2021 Zakhary Kaplan. All rights reserved.
//
//  SPDX-License-Identifier: MIT
//

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
