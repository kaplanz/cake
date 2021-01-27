//
//  foo.cpp
//  Cake demo source.
//
//  Created by Zakhary Kaplan on 2021-01-05.
//  Copyright © 2021 Zakhary Kaplan. All rights reserved.
//
//  SPDX-License-Identifier: MIT
//

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
