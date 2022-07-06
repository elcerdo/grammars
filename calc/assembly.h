#pragma once

#include <cstddef>
#include <optional>

namespace assembly {

auto run_parser(const size_t nn) -> std::optional<size_t>;

}
