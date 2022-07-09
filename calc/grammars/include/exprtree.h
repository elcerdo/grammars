#pragma once

#include <string>

#include <lemon/list_graph.h>

namespace assembly {

auto run_parser(const std::string& source) -> std::optional<float>;

}
