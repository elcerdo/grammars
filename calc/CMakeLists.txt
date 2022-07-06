cmake_minimum_required(VERSION 3.17)
project(calculator CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(BISON 3.2)

bison_target(assembly_parser
    assembly.yy
    "${CMAKE_CURRENT_BINARY_DIR}/assembly_parser.tab.cpp"
    DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/assembly_parser.tab.h"
    )

add_executable(calc)
target_sources(calc
    PUBLIC
    assembly.h
    PRIVATE
    ${BISON_assembly_parser_OUTPUTS}
    main.cpp
    )
target_include_directories(calc
    PRIVATE
    .
    )
target_link_libraries(calc
    PRIVATE
    )
target_compile_definitions(calc
    PRIVATE
    #YYDEBUG
    )
