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
    else spdlog::warn("FAILED");
  }
}

void test_assembly(const nlohmann::json& jj)
{

  spdlog::critical("test assembly");

  spdlog::info("input jj\n{}", jj.dump(2));

  const auto ret = assembly::run_parser(jj);

  if (ret) spdlog::info("OK GOT {}", *ret);
  else spdlog::warn("FAILED");
}

int main(int argc, char* argv[])
{
  spdlog::set_level(spdlog::level::debug);

  test_fblist(5);


  test_assembly(nlohmann::json{
    {
      {"opcode", "foo"},
      {"xx", 42},
    },
    {
      {"opcode", "bar"},
      {"xx", -5},
      {"yy", 1},
    },
  });

  test_assembly(nlohmann::json{
    {
      {"opcode", "func_start"},
      {"func_id", 0xf0},
    },
    {
      {"opcode", "func_arg"},
      {"var_id", "tmp000"},
    },
    {
      {"opcode", "func_end"},
    },
  });

  return 0;
}
