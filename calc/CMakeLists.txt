cmake_minimum_required(VERSION 3.17)
project(calculator CXX)

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


