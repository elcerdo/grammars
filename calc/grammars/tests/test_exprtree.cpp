#include <catch2/catch.hpp>

#include <exprtree.h>
#include <lemon/bfs.h>

#include <spdlog/spdlog.h>

#include <optional>
#include <filesystem>
#include <fstream>

TEST_CASE("test lemon", "[grammars][lemon][exprtree]")
{
  using Graph = lemon::ListDigraph;

  Graph graph;
  const auto na = graph.addNode();

  REQUIRE(lemon::countNodes(graph) == 1);
  REQUIRE(lemon::countArcs(graph) == 0);

  const auto nb = graph.addNode();

  REQUIRE(lemon::countNodes(graph) == 2);
  REQUIRE(lemon::countArcs(graph) == 0);

  const auto e0 = graph.addArc(na, nb);

  REQUIRE(lemon::countNodes(graph) == 2);
  REQUIRE(lemon::countArcs(graph) == 1);
}

void test_exprtree(
  const std::string& input,
  const std::optional<std::tuple<size_t>> ret_,
  const std::filesystem::path& dot_path = "")
{
  using exprtree::Graph;
  using NodeIt = Graph::NodeIt;
  using ArcIt = Graph::ArcIt;
  using namespace lemon;

  spdlog::critical("test exprtree");

  spdlog::info("input \"{}\"", input);

  const auto ret = exprtree::run_parser(input);

  spdlog::info(ret ? "SUCCESS" : "FAILED");

  REQUIRE(static_cast<bool>(ret) == static_cast<bool>(ret_));

  if (!ret)
    return;

  REQUIRE(ret);
  auto& graph = ret->graph;
  const auto& node_to_func_args = ret->node_to_func_args;
  const auto& arc_to_names = ret->arc_to_names;
  const auto& ret_node = ret->ret_node;
  const auto& func_protos = ret->func_protos;

  spdlog::info("num_nodes {} num_arcs {} has_ret_node {} num_func_protos {}",
    countNodes(graph),
    countArcs(graph),
    graph.valid(ret_node),
    func_protos.size());

  Graph::NodeMap<int> node_to_distances(graph, -1);
  if (graph.valid(ret_node)) {
    spdlog::info("running bfs");
    lemon::bfs(graph).distMap(node_to_distances).run(ret_node);
  }

  for (NodeIt ni(graph); ni!=INVALID; ++ni) {
    const auto& [type, name] = node_to_func_args[ni];
    spdlog::info("NN{:03d} dist {:2} type {} out {} in {} \"{}\"{}",
      graph.id(ni),
      node_to_distances[ni],
      type,
      countOutArcs(graph, ni),
      countInArcs(graph, ni),
      name,
      ni == ret_node ? " RETURN" : "");
  }

  if (!dot_path.empty()) { // dot dump
    spdlog::info("saving \"{}\"", dot_path.string());
    using std::endl;
    std::ofstream handle(dot_path.string().c_str());
    handle << "digraph {" << endl;
    for (NodeIt ni(graph); ni!=INVALID; ++ni) {
      const auto is_reached = node_to_distances[ni] >= 0;
      const auto& [node_type, node_name] = node_to_func_args[ni];
      const auto shape = fmt::format("{}{}",
        is_reached ? "double" : "",
        ni == ret_node ? "octagon" : "circle");
      handle << fmt::format("nn{:03d} [label=\"{} {}\" shape={}];",
        graph.id(ni),
        exprtree::to_string(node_type),
        node_name,
        shape) << endl;
    }
    for (ArcIt ai(graph); ai!=INVALID; ++ai)
      handle << fmt::format("nn{:03d} -> nn{:03d} [label=\"{}\"];",
        graph.id(graph.source(ai)),
        graph.id(graph.target(ai)),
        arc_to_names[ai]) << endl;
    handle << "}" << endl;
  }

  REQUIRE(ret_);
  REQUIRE(ret->func_protos.size() == std::get<0>(*ret_));
}

TEST_CASE("test exprtree", "[grammars][exprtree]")
{
  test_exprtree("", std::make_tuple(0));
  test_exprtree("float hello();", std::make_tuple(1));
  test_exprtree("floathello();", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa,float bb);", std::make_tuple(1));
  test_exprtree("floatcoucou(vec2 aa, float bb);", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa, float bb);", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa , float bb);", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa, floatbb);", std::make_tuple(1));
  test_exprtree("float coucou(vec2aa, float bb);", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa,);", {});
  test_exprtree("float coucou(, float bb);", {});
  test_exprtree("float coucou(,);", {});
  test_exprtree("float coucou(vec2 aa,float bb);", std::make_tuple(1));
  test_exprtree("float coucou (vec2 aa, float bb);", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa, float bb) ;", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa, flot bb);", {});
  test_exprtree(" float coucou(vec2 aa, float bb);", std::make_tuple(1));
  test_exprtree("float coucou(vec2 aa, float bb); ", std::make_tuple(1));
  test_exprtree(" float coucou(vec2 aa, float bb); ", std::make_tuple(1));
  test_exprtree(" float coucou ( vec2 aa , float bb ) ; ", std::make_tuple(1));
  test_exprtree("float hello(float aa); float world();", std::make_tuple(2));
  test_exprtree("float hello(float aa);; float world();;;;", std::make_tuple(2));
  test_exprtree(R"(float hello(float aa);
   float world();)", std::make_tuple(2));
  test_exprtree(R"(

float coucou(vec2 aa, float bb);
float hello(float bb);
float world(vec2 bb);

)", std::make_tuple(3));
  test_exprtree(R"(

float coucou(vec2 aa, float bb);
vec2 coucou(float aa, float bb);

)", {});
  test_exprtree(R"(
;
float coucou(vec2 aa, float bb);
float hello(float bb);
   ;;
float world(vec2 bb);
;
)", std::make_tuple(3));

  test_exprtree(R"(

float coucou(vec2 aa, float bb) {
  return bb;
}

)", std::make_tuple(1));
  test_exprtree(R"(

float coucou(vec2 aa, float bb) {
  return bb;
  return aa;
}

)", {});
  test_exprtree(R"(

float coucou(vec2 aa, float bb) {
  vec2 xx = aa;
}

)", {});
  test_exprtree(R"(

float coucou(vec2 aa, float bb) {
  return cc;
}

)", {});
  test_exprtree(R"(

float coucou(float aa, float bb) {
  float cc = aa + bb;
  return bb + aa;
}

)", std::make_tuple(1));
  test_exprtree(R"(

vec2 coucou(vec2 aa, vec2 bb) {
  vec2 cc = aa + bb;
  return cc + aa;
}

)", std::make_tuple(1));
  test_exprtree(R"(

vec2 coucou(vec2 aa, vec2 bb) {
  vec2 cc = aa + bb;
  return cc + aa * cc;
}

)", std::make_tuple(1));
  test_exprtree(R"(

vec2 coucou(vec2 aa, vec2 bb) {
  vec2 cc = aa + bb;
  vec2 dd = bb + cc;
  return cc + (aa * cc);
}

)", std::make_tuple(1), "example00.dot");
  test_exprtree(R"(

float length(vec2 xx);
vec2 foo(float xx);

float coucou(vec2 aa, float bb) {
  return length(aa * foo(bb)) + bb;
}

)", std::make_tuple(3), "example01.dot");
}
