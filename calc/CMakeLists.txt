cmake_minimum_required(VERSION 3.17)
project(calculator CXX)

find_package(BISON 3.2)

add_executable(calc)
target_sources(calc
    PRIVATE
    Driver.h
    PRIVATE
    main.cpp
    Driver.cpp
    )
target_include_directories(calc
    PRIVATE
    .
    )


