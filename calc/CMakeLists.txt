cmake_minimum_required(VERSION 3.17)
project(calculator CXX)
set(CMAKE_CXX_STANDARD 17)
cmake_policy(SET CMP0135 NEW)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

include(catch2)

enable_testing()

add_subdirectory(grammars)
