cmake_minimum_required(VERSION 3.17)
project(calculator CXX)

find_package(BISON 3.2)

bison_target(assembly_parser
    assembly.yy
    "${CMAKE_CURRENT_BINARY_DIR}/assembly_parser.cpp"
    )

add_executable(calc)
target_sources(calc
    PRIVATE
    Driver.h
    PRIVATE
    main.cpp
    Driver.cpp
    ${BISON_assembly_parser_OUTPUTS}
    )
target_include_directories(calc
    PRIVATE
    .
    )
target_link_libraries(calc
    PRIVATE
    )


