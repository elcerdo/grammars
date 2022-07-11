#pragma once

#include <string>
#include <tuple>
#include <list>
#include <unordered_map>
#include <memory>

#include <lemon/list_graph.h>

namespace exprtree {

enum struct TypeId {
  Float,
  Vec2,
  Undefined,
};

using IdentId = std::string;

using FuncArg = std::tuple<TypeId, IdentId>;
using FuncArgs = std::list<FuncArg>;

using Graph = lemon::ListDigraph;
using FuncPrototypes = std::unordered_map<IdentId, std::tuple<TypeId, FuncArgs>>;
using DefinedVars = std::unordered_map<IdentId, Graph::Node>;

struct Payload {
  Payload();
  Graph graph;
  Graph::NodeMap<FuncArg> node_to_func_args;
  Graph::ArcMap<IdentId> arc_to_names;
  DefinedVars defined_vars = {};
  Graph::Node ret_node = lemon::INVALID;

  FuncPrototypes func_protos = {};
  size_t num_empty_declarations = 0;
};

std::string to_string(const TypeId type_id);
auto run_parser(const std::string& source) -> std::unique_ptr<Payload>;

}
