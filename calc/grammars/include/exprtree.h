#pragma once

#include <string>
#include <tuple>
#include <vector>
#include <unordered_map>

#include <lemon/list_graph.h>

namespace exprtree {


enum struct TypeId {
  Float,
  Vec2,
  Undefined,
};

using IdentId = std::string;

using FuncArg = std::tuple<TypeId,IdentId>;
using FuncArgs = std::vector<FuncArg>;

using Graph = lemon::ListDigraph;
using FuncPrototypes = std::unordered_map<IdentId, std::tuple<TypeId, FuncArgs>>;

struct Payload {
  Payload();
  Graph graph;
  Graph::NodeMap<int> foobar;

  FuncPrototypes func_protos;
};

auto run_parser(const std::string& source) -> std::unique_ptr<Payload>;

}
