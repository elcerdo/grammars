%language "c++"
%require "3.2"
%skeleton "lalr1.cc"
%define api.namespace {assembly}
%define api.token.constructor
%define api.value.type variant

%{

#include <assembly.h>

#include <spdlog/spdlog.h>
#include <spdlog/fmt/bundled/ranges.h>

#include <vector>
#include <functional>
#include <unordered_map>

using FuncId = size_t;
using VarId = std::string;
using Scalar = float;

using NullaryFunctor = std::function<Scalar()>;
using UnaryFunctor = std::function<Scalar(Scalar)>;
using BinaryFunctor = std::function<Scalar(Scalar, Scalar)>;

struct LexerState {
  using Container = std::vector<nlohmann::json>;
  Container::const_iterator input_current;
  const Container::const_iterator input_end;
};

struct ParserState {
  float result_value;
  std::unordered_map<VarId, Scalar> var_id_to_values;
  std::unordered_map<FuncId, NullaryFunctor> func_id_to_nullary_functors;
  std::unordered_map<FuncId, UnaryFunctor> func_id_to_unary_functors;
  std::unordered_map<FuncId, BinaryFunctor> func_id_to_binary_functors;
};

%}

%parse-param {LexerState& lex_state} {ParserState& parser_state}
%lex-param {LexerState& lex_state}

%code
{
  namespace assembly
  {
    // Return the next token.
    auto yylex(LexerState& lex_state) -> parser::symbol_type;
  }
}

%token END 0
%token<FuncId> FUNC_START
%token FUNC_END
%token<VarId> VAR_LOOKUP

%nterm<Scalar> expr func_call var_lookup
%nterm<std::vector<Scalar>> func_args

%start result

%% /* Grammar rules and actions follow */

result: expr {
  parser_state.result_value = $1;
  spdlog::debug("[result] value {}",
    parser_state.result_value);
}

expr: func_call
    | var_lookup

var_lookup: VAR_LOOKUP {
  const auto iter_value = parser_state.var_id_to_values.find($1);
  if (iter_value == std::cend(parser_state.var_id_to_values))
    throw syntax_error("unknown var");
  assert(iter_value != std::cend(parser_state.var_id_to_values));
  spdlog::debug("[var_lookup] id {} value {}",
    $1,
    iter_value->second);
  $$ = iter_value->second;
}

func_call: FUNC_START func_args FUNC_END {
  const auto num_args = $2.size();
  switch (num_args) {
  case 0:
    { // dispatch nullary
      const auto& func_id_to_functors = parser_state.func_id_to_nullary_functors;
      const auto iter_functor = func_id_to_functors.find($1);
      if (iter_functor == std::cend(func_id_to_functors))
        throw syntax_error("unknown nullary func");
      assert(iter_value != std::cend(func_id_to_functors));
      spdlog::debug("[func_call] func {} args ({})",
        $1,
        fmt::join($2, ","));
      $$ = iter_functor->second();
    }
    break;
  case 1:
    { // dispatch unary
      const auto& func_id_to_functors = parser_state.func_id_to_unary_functors;
      const auto iter_functor = func_id_to_functors.find($1);
      if (iter_functor == std::cend(func_id_to_functors))
        throw syntax_error("unknown unary func");
      assert(iter_value != std::cend(func_id_to_functors));
      spdlog::debug("[func_call] func {} args ({})",
        $1,
        fmt::join($2, ","));
      $$ = iter_functor->second($2[0]);
    }
    break;
  case 2:
    { // dispatch binary
      const auto& func_id_to_functors = parser_state.func_id_to_binary_functors;
      const auto iter_functor = func_id_to_functors.find($1);
      if (iter_functor == std::cend(func_id_to_functors))
        throw syntax_error("unknown binary func");
      assert(iter_value != std::cend(func_id_to_functors));
      spdlog::debug("[func_call] func {} args ({})",
        $1,
        fmt::join($2, ","));
      $$ = iter_functor->second($2[0], $2[1]);
    }
    break;
  default:
    throw syntax_error("bad num args");
    break;
  }
}

func_args: %empty { $$ = {}; }
         | func_args expr { $$ = $1; $$.emplace_back($2); }

/* list  : %empty      { $$ = {}; }
      | list NUMBER { $$ = $1; $$.emplace_back($2); }
      | list FIZZ { $$ = $1; spdlog::debug("FIZZ"); }
      | list BUZZ { $$ = $1; spdlog::debug("BUZZ"); } */

%% /* Other definitions */

constexpr size_t shash(char const * ii)
{
  size_t seed = 0xa578ffb2;
  while (*ii != 0)
    seed ^= static_cast<size_t>(*ii++) + 0x9e3779b9 + (seed<<6) + (seed>>2);
  return seed;
}

auto assembly::yylex(LexerState& lex_state) -> parser::symbol_type
{
  if (lex_state.input_current >= lex_state.input_end)
    return parser::make_END();

  const auto& current = *lex_state.input_current++;

  constexpr auto func_start_hash = shash("func_start");
  constexpr auto func_end_hash = shash("func_end");
  constexpr auto var_lookup_hash = shash("var_lookup");
  const auto opcode_hash = shash(current.at("opcode").get<std::string>().c_str());

  switch (opcode_hash) {
    case func_start_hash:
      return parser::make_FUNC_START(current.at("func_id").get<FuncId>());
    case func_end_hash:
      return parser::make_FUNC_END();
    case var_lookup_hash:
      return parser::make_VAR_LOOKUP(current.at("var_id").get<VarId>());
    default:
      assert(false);
      return parser::make_END();
  }
}

auto assembly::parser::error(const std::string& msg) -> void
{
  spdlog::debug("[parser_error] {}", msg);
}

auto assembly::run_parser(const nlohmann::json& jj, const float xx_value) -> std::optional<float>
{
  if (!jj.is_array())
    return {};

  const auto kk = jj.get<LexerState::Container>();
  spdlog::debug("[run_parser] num_opcodes {}", kk.size());
  LexerState lex_state {
    std::cbegin(kk),
    std::cend(kk),
  };

  ParserState parser_state;
  parser_state.var_id_to_values["xx"] = xx_value;
  parser_state.func_id_to_nullary_functors[FUNC_ZERO] = []() -> Scalar { return 0; };
  parser_state.func_id_to_nullary_functors[FUNC_ONE] = []() -> Scalar { return 1; };
  parser_state.func_id_to_unary_functors[FUNC_DOUBLE] = [](const Scalar xx) -> Scalar { return 2 * xx; };
  parser_state.func_id_to_unary_functors[FUNC_MINUS_ONE] = [](const Scalar xx) -> Scalar { return xx - 1; };
  parser_state.func_id_to_binary_functors[FUNC_ADD] = [](const Scalar xx, const Scalar yy) -> Scalar { return xx + yy; };

  assembly::parser parser(lex_state, parser_state);

#if YYDEBUG
  parser.set_debug_stream(std::cout);
  parser.set_debug_level(1);
#endif

  try {
    const auto parsing_err = parser();
    spdlog::debug("[run_parser] parsing_err {}", parsing_err);
    if (parsing_err) return {};
    return parser_state.result_value;
  } catch (nlohmann::json::exception& exc) {
    spdlog::debug("[json_error] {}", exc.what());
    return {};
  }
}
