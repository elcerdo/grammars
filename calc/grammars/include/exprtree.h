#pragma once

#include <string>

#include <lemon/list_graph.h>

namespace exprtree {

using Graph = lemon::ListDigraph;

enum struct TypeId {
  Float,
  Vec2,
  Undefined,
};

struct Payload {
  Payload();
  Graph graph;
  Graph::NodeMap<int> foobar;
};

auto run_parser(const std::string& source) -> std::unique_ptr<Payload>;

}
