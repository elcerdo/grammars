#pragma once

#include <nlohmann/json.hpp>

namespace assembly {

auto run_parser(const nlohmann::json& jj, const float xx_value) -> std::optional<float>;

}
