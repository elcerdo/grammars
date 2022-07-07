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
    12,
  }, 0, {})) return 1;

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
  }, 2, {})) return 1;

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

  { // call to undefined 0-arg func program
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_UNDEFINED},
      },
      {
        {"opcode", "func_end"},
      },
    };
    if (!test_assembly(opcodes, 3, {})) return 1;
  }

  { // simple 0-arg func program that returns zero
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_ZERO},
      },
      {
        {"opcode", "func_end"},
      },
    };
    if (!test_assembly(opcodes, 3, 0)) return 1;
    if (!test_assembly(opcodes, 5, 0)) return 1;
  }

  { // simple 0-arg func program that returns one
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_ONE},
      },
      {
        {"opcode", "func_end"},
      },
    };
    if (!test_assembly(opcodes, 3, 1)) return 1;
    if (!test_assembly(opcodes, 5, 1)) return 1;
  }

  { // simple 1-arg func program that double its argument
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_DOUBLE},
      },
      {
        {"opcode", "var_lookup"},
        {"var_id", "xx"},
      },
      {
        {"opcode", "func_end"},
      },
    };
    if (!test_assembly(opcodes, 3, 6)) return 1;
    if (!test_assembly(opcodes, 5, 10)) return 1;
    if (!test_assembly(opcodes, -1, -2)) return 1;
  }

  { // nested 1-arg func program that returns (xx - 1) * 2
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_DOUBLE},
      },
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_MINUS_ONE},
      },
      {
        {"opcode", "var_lookup"},
        {"var_id", "xx"},
      },
      {
        {"opcode", "func_end"},
      },
      {
        {"opcode", "func_end"},
      },
    };
    if (!test_assembly(opcodes, 3, 4)) return 1;
    if (!test_assembly(opcodes, 5, 8)) return 1;
    if (!test_assembly(opcodes, -1, -4)) return 1;
  }

  { // binary func program that returns xx + 1
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_ADD},
      },
      {
        {"opcode", "func_start"},
        {"func_id", assembly::FUNC_ONE},
      },
      {
        {"opcode", "func_end"},
      },
      {
        {"opcode", "var_lookup"},
        {"var_id", "xx"},
      },
      {
        {"opcode", "func_end"},
      },
    };
    if (!test_assembly(opcodes, 3, 4)) return 1;
    if (!test_assembly(opcodes, 5, 8)) return 1;
    if (!test_assembly(opcodes, -1, -4)) return 1;
  }

  return 0;
}
