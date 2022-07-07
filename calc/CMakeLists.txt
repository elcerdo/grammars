cmake_minimum_required(VERSION 3.17)
project(calculator CXX)
set(CMAKE_CXX_STANDARD 17)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

include(spdlog)
include(nlohmann_json)

find_package(BISON 3.2)

bison_target(fblist_parser
    fblist.yy
    "${CMAKE_CURRENT_BINARY_DIR}/fblist_parser.tab.cpp"
    DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/fblist_parser.tab.h"
    )

bison_target(assembly_parser
    assembly.yy
    "${CMAKE_CURRENT_BINARY_DIR}/assembly_parser.tab.cpp"
    DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/assembly_parser.tab.h"
    )

add_executable(calc)
target_sources(calc
    PUBLIC
    fblist.h
    PRIVATE
    ${BISON_fblist_parser_OUTPUTS}
    main.cpp
    )
target_include_directories(calc
    PRIVATE
    .
    )
target_link_libraries(calc
    PRIVATE
    spdlog::spdlog
    nlohmann_json::nlohmann_json
    )
target_compile_definitions(calc
    PRIVATE
    #YYDEBUG
    )
