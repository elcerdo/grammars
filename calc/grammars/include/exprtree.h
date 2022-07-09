#pragma once

#include <string>
#include <optional>

#include <lemon/list_graph.h>

namespace exprtree {

struct Payload {
  using Graph = lemon::ListDigraph;

  Graph graph;
};

auto run_parser(const std::string& source) -> std::optional<Payload>;

}
