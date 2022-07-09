cmake_minimum_required(VERSION 3.17)
project(calculator CXX)
set(CMAKE_CXX_STANDARD 17)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

include(catch2)

enable_testing()

add_subdirectory(grammars)

add_executable(calc)
target_sources(calc
  PRIVATE
  main.cpp)
target_include_directories(calc
  PRIVATE
  .
  )
target_link_libraries(calc
  PRIVATE
  grammars
  spdlog::spdlog
  )
