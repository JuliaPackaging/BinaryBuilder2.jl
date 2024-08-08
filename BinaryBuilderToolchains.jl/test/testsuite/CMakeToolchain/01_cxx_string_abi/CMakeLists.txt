cmake_minimum_required(VERSION 3.13)  # CMake version check
project(simple_example)               # Create project "simple_example"

set(LIBSTRING_FILES libstring.cpp)
add_library(string SHARED ${LIBSTRING_FILES})

set(SOURCE_FILES cxx_string_abi.cpp)
add_executable(cxx_string_abi ${SOURCE_FILES})
target_link_libraries(cxx_string_abi string)
