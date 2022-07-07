#pragma once

#include <nlohmann/json.hpp>

namespace assembly {

constexpr size_t FUNC_ZERO = 0xf0;
constexpr size_t FUNC_ONE = 0xf1;

auto run_parser(const nlohmann::json& jj, const float xx_value) -> std::optional<float>;

}
