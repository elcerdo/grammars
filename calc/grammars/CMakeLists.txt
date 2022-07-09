include(spdlog)
include(nlohmann_json)
include(lemon)
find_package(BISON 3.2)

bison_target(fblist_parser
  src/fblist.yy
  "${CMAKE_CURRENT_BINARY_DIR}/fblist_parser.tab.cpp"
  DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/fblist_parser.tab.h"
  )

bison_target(assembly_parser
  src/assembly.yy
  "${CMAKE_CURRENT_BINARY_DIR}/assembly_parser.tab.cpp"
  DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/assembly_parser.tab.h"
  )

bison_target(exprtree_parser
  src/exprtree.yy
  "${CMAKE_CURRENT_BINARY_DIR}/exprtree_parser.tab.cpp"
  DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/exprtree_parser.tab.h"
  )

add_library(grammars STATIC)
target_sources(grammars
  PUBLIC
  include/exprtree.h
  include/fblist.h
  include/assembly.h
  PRIVATE
  ${BISON_fblist_parser_OUTPUTS}
  ${BISON_assembly_parser_OUTPUTS}
  ${BISON_exprtree_parser_OUTPUTS}
  )
target_include_directories(grammars
  PUBLIC
  include

  )
target_link_libraries(grammars
  PUBLIC
  nlohmann_json::nlohmann_json
  lemon::lemon
  PRIVATE
  spdlog::spdlog
  )
target_compile_definitions(grammars
  PRIVATE
  #YYDEBUG
  )

add_subdirectory(tests)
