#include <iostream>
#include <stdexcept>
#include <string>

extern "C" {
#include "libanswer.h"
}

static int checked_answer(int x) {
    if (x < 0) {
        throw std::runtime_error("negative input " + std::to_string(x));
    }
    return answer(x);
}

int main() {
    try {
        checked_answer(-1);
    } catch (const std::exception & e) {
        std::cout << "caught: " << e.what() << std::endl;
    }
    std::cout << "answer(7) == " << checked_answer(7) << std::endl;
    return 0;
}
