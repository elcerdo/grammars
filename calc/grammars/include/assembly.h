#pragma once

#include <nlohmann/json.hpp>

#include <optional>

namespace assembly {

enum struct FuncId {
  Zero,
  One,
  TimesTwo,
  MinusOne,
  Add,
  Undefined,
};

auto run_parser(const nlohmann::json& jj, const float xx_value) -> std::optional<float>;

}
