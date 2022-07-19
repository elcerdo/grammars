
add_executable(test_wrappers)
target_sources(test_wrappers
  PRIVATE
  test_item_aa.cpp
  test_main.cpp
)
target_link_libraries(test_wrappers
  PRIVATE
  Catch2::Catch2
  spdlog::spdlog
)

add_test(test_wrappers test_wrappers)
