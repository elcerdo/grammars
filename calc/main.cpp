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

bool test_assembly(
  const nlohmann::json& jj,
  const float xx_value,
  const std::optional<float> ret_)
{

  spdlog::critical("test assembly");

  spdlog::info("input jj\n{}", jj.dump(2));
  spdlog::info("xx_value {}", xx_value);

  const auto ret = assembly::run_parser(jj, xx_value);

  if (ret) spdlog::info("yy_value {}", *ret);
  else spdlog::info("FAILED");

  return ret == ret_;
}

int main(int argc, char* argv[])
{
  spdlog::set_level(spdlog::level::debug);

  test_fblist(5);

  if (!test_assembly(nlohmann::json{
    {
      {"opcode", "foo"},
      {"xx", 42},
    },
    {
      {"opcode", "bar"},
      {"xx", -5},
      {"yy", 1},
    },
  }, 0, {})) return 1;

  if (!test_assembly(nlohmann::json{
    {
      {"opcode", "var_lookup"},
      {"var_id", "tmp000"},
    },
  }, 2, std::nan("")) == std::nan("invalid-var-id")) return 1;

  { // simple lookup program
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "var_lookup"},
        {"var_id", "xx"},
      },
    };
    if (!test_assembly(opcodes, 3, 3)) return 1;
    if (!test_assembly(opcodes, 5, 5)) return 1;
  }

  { // simple 0-arg func program
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", 0xf0},
      },
      {
        {"opcode", "func_end"},
      },
    };
    if (!test_assembly(opcodes, 3, 42.5)) return 1;
    if (!test_assembly(opcodes, 5, 42.5)) return 1;
  }

  if (!test_assembly(nlohmann::json{
    {
      {"opcode", "func_start"},
      {"func_id", 0xf0},
    },
    {
      {"opcode", "func_arg"},
      {"var_id", "xx"},
    },
    {
      {"opcode", "func_end"},
    },
  }, 1, 12.)) return 1;


  return 0;
}
