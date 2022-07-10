#include <catch2/catch.hpp>

#include <assembly.h>

#include <spdlog/spdlog.h>

void test_assembly(
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

  REQUIRE(ret == ret_);
}

TEST_CASE("test assembly", "[grammars][assembly]")
{
  using assembly::FuncId;

  test_assembly(nlohmann::json{
    12,
  }, 0, {});

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
  }, 0, {});

  test_assembly(nlohmann::json{
    {
      {"opcode", "var_lookup"},
      {"var_id", "tmp000"},
    },
  }, 2, {});

  { // simple lookup program
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "var_lookup"},
        {"var_id", "xx"},
      },
    };
    test_assembly(opcodes, 3.f, 3.f);
    test_assembly(opcodes, 5.f, 5.f);
  }

  { // call to undefined 0-arg func program
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::Undefined},
      },
      {
        {"opcode", "func_end"},
      },
    };
    test_assembly(opcodes, 3.f, {});
  }

  { // simple 0-arg func program that returns zero
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::Zero},
      },
      {
        {"opcode", "func_end"},
      },
    };
    test_assembly(opcodes, 3.f, 0.f);
    test_assembly(opcodes, 5.f, 0.f);
  }

  { // simple 0-arg func program that returns one
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::One},
      },
      {
        {"opcode", "func_end"},
      },
    };
    test_assembly(opcodes, 3.f, 1.f);
    test_assembly(opcodes, 5.f, 1.f);
  }

  { // simple 1-arg func program that double its argument
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::TimesTwo},
      },
      {
        {"opcode", "var_lookup"},
        {"var_id", "xx"},
      },
      {
        {"opcode", "func_end"},
      },
    };
    test_assembly(opcodes, 3.f, 6.f);
    test_assembly(opcodes, 5.f, 10.f);
    test_assembly(opcodes, -1.f, -2.f);
  }

  { // nested 1-arg func program that returns (xx - 1) * 2
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::TimesTwo},
      },
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::MinusOne},
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
    test_assembly(opcodes, 3.f, 4.f);
    test_assembly(opcodes, 5.f, 8.f);
    test_assembly(opcodes, -1.f, -4.f);
  }

  { // binary func program that returns xx + 1
    const auto opcodes = nlohmann::json{
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::Add},
      },
      {
        {"opcode", "func_start"},
        {"func_id", FuncId::One},
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
    test_assembly(opcodes, 3.f, 4.f);
    test_assembly(opcodes, 5.f, 6.f);
    test_assembly(opcodes, -1.f, 0.f);
  }

}
