
add_executable(test_grammars)
target_sources(test_grammars
  PRIVATE
  test_fblist.cpp
  test_assembly.cpp
  test_exprtree.cpp
  test_main.cpp
)
target_link_libraries(test_grammars
  PRIVATE
  Catch2::Catch2
  grammars
  spdlog::spdlog
)

add_test(test_grammars test_grammars)
