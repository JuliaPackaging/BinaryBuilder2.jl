#include <iostream>
#include "libstring.h"

int main() {
    std::string Skywalker = "This is outrageous, it's unfair! ";
    std::string Windu = "Take a seat, young Skywalker.";
    std::string true_masterpiece = string_cat(Skywalker, Windu);
    std::cout << true_masterpiece << "\n";
    return 0;
}
