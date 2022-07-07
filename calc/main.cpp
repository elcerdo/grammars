#include <assembly.h>
#include <fblist.h>

#include <spdlog/spdlog.h>

void test_fblist(const size_t kk_max)
{
  spdlog::critical("test fblist");

  for (size_t kk = 0; kk < kk_max; kk++) {
    spdlog::info("{:03d} =============", kk);
    const auto ret = fblist::run_parser(kk);
    if (ret) spdlog::info("OK GOT {}", *ret);
    else spdlog::info("ERROR");
  }
}

void test_assembly(const nlohmann::json& jj)
{

  spdlog::critical("test assembly");

  spdlog::info("input jj\n{}", jj.dump(2));

  const auto ret = assembly::run_parser(jj);

  if (ret) spdlog::info("OK GOT {}", *ret);
  else spdlog::info("ERROR");
}

int main(int argc, char* argv[])
{
  // spdlog::set_level(spdlog::level::debug);

  test_fblist(5);

  const auto jj_test = nlohmann::json{
    {
      {"opcode", "foo"},
      {"xx", 42},
    },
    {
      {"opcode", "bar"},
      {"xx", 42},
    },
  };

  test_assembly(jj_test);

  return 0;
}
