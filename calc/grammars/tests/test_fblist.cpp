#include <catch2/catch.hpp>

#include <fblist.h>

#include <spdlog/spdlog.h>

TEST_CASE("test fblist", "[grammars][fblist]")
{
  constexpr size_t kk_max = 20;

  spdlog::critical("test fblist");

  for (size_t kk = 0; kk < kk_max; kk++) {
    spdlog::info("{:03d} =============", kk);
    const auto ret = fblist::run_parser(kk);

    if (ret) spdlog::info("OK GOT {}", *ret);
    else spdlog::warn("FAILED");

    REQUIRE(ret);
  }
}
