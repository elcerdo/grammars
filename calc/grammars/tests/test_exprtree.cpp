#include <catch2/catch.hpp>

#include <exprtree.h>

#include <spdlog/spdlog.h>

TEST_CASE("test lemon", "[grammars][lemon]")
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

void test_exprtree(const std::string& input, const std::optional<std::tuple<size_t>> ret_)
{
  spdlog::critical("test exprtree");

  spdlog::info("input\n{}", input);

  const auto ret = exprtree::run_parser(input);

  spdlog::info(ret ? "SUCCESS" : "FAILED");

  REQUIRE(static_cast<bool>(ret) == static_cast<bool>(ret_));

  if (ret) {
    REQUIRE(ret_);
    const auto& [num_func_protos] = *ret_;
    REQUIRE(ret->func_protos.size() == num_func_protos);
  }
}

TEST_CASE("test exprtree", "[grammars][exprtree]")
{
  test_exprtree("", 0);
  test_exprtree("float hello()", 1);
  test_exprtree("float coucou(vec2 aa, float bb)", 1);
  test_exprtree("float coucou(vec2 aa, flot bb)", {});
}
