#pragma once

#include <nlohmann/json.hpp>

namespace assembly {

constexpr size_t FUNC_ZERO = 0xf0;
constexpr size_t FUNC_ONE = 0xf1;
constexpr size_t FUNC_DOUBLE = 0xf2;
constexpr size_t FUNC_MINUS_ONE = 0xf3;
constexpr size_t FUNC_ADD = 0xf4;
constexpr size_t FUNC_UNDEFINED = 0xf5;

auto run_parser(const nlohmann::json& jj, const float xx_value) -> std::optional<float>;

}
