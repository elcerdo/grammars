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

void test_exprtree(const std::string& input, const std::optional<std::tuple<size_t, size_t>> ret_)
{
  spdlog::critical("test exprtree");

  spdlog::info("input \"{}\"", input);

  const auto ret = exprtree::run_parser(input);

  spdlog::info(ret ? "SUCCESS" : "FAILED");

  REQUIRE(static_cast<bool>(ret) == static_cast<bool>(ret_));

  if (ret) {
    REQUIRE(ret_);
    const auto& [num_func_protos, num_empty_statements] = *ret_;
    REQUIRE(ret->func_protos.size() == num_func_protos);
    REQUIRE(ret->num_empty_statements == num_empty_statements);
  }
}

TEST_CASE("test exprtree", "[grammars][exprtree]")
{
  test_exprtree("", std::make_tuple(0, 0));
  test_exprtree("float hello();", std::make_tuple(1, 0));
  test_exprtree("floathello();", {});
  test_exprtree("float coucou(vec2 aa, float bb);", std::make_tuple(1, 0));
  test_exprtree("float coucou(vec2 aa , float bb);", std::make_tuple(1, 0));
  test_exprtree("float coucou(vec2 aa, floatbb);", {});
  test_exprtree("float coucou(vec2aa, float bb);", {});
  test_exprtree("floatcoucou(vec2 aa, float bb);", {});
  test_exprtree("float coucou(vec2 aa,);", {});
  test_exprtree("float coucou(, float bb);", {});
  test_exprtree("float coucou(,);", {});
  test_exprtree("float coucou(vec2 aa,float bb);", std::make_tuple(1, 0));
  test_exprtree("float coucou (vec2 aa, float bb);", std::make_tuple(1, 0));
  test_exprtree("float coucou(vec2 aa, float bb) ;", std::make_tuple(1 ,0));
  test_exprtree("float coucou(vec2 aa, flot bb);", {});
  test_exprtree(" float coucou(vec2 aa, float bb);", std::make_tuple(1 ,0));
  test_exprtree("float coucou(vec2 aa, float bb); ", std::make_tuple(1, 0));
  test_exprtree(" float coucou(vec2 aa, float bb); ", std::make_tuple(1, 0));
  test_exprtree(" float coucou ( vec2 aa , float bb ) ; ", std::make_tuple(1, 0));
  test_exprtree(R"(

float coucou(vec2 aa, float bb);
float hello(float bb);
float world(vec2 bb);

)", std::make_tuple(3, 0));
  test_exprtree(R"(
;
float coucou(vec2 aa, float bb);
float hello(float bb);
   ;;
float world(vec2 bb);
;
)", std::make_tuple(3, 4));
}
