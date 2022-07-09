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

TEST_CASE("test exprtree", "[grammars][exprtree]")
{
  spdlog::critical("test exprtree");

  const auto ret = exprtree::run_parser("float coucou(float aa, float bb)");
  REQUIRE(ret);

}
