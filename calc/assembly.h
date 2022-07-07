#pragma once

#include <nlohmann/json.hpp>

namespace assembly {

auto run_parser(const nlohmann::json& jj) -> std::optional<size_t>;

}
