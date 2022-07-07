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

struct LexerState {
  using Container = std::vector<nlohmann::json>;
  Container::const_iterator input_current;
  const Container::const_iterator input_end;
};

struct ParserState {
  float result_value;
  std::unordered_map<VarId, Scalar> var_id_to_values;
  std::unordered_map<FuncId, NullaryFunctor> func_id_to_nullary_functors;
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
%token<VarId> FUNC_ARG VAR_LOOKUP
%token FUNC_END

%nterm<Scalar> expr func_call var_lookup

%nterm<std::vector<VarId>> func_args

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
  const auto found_value = iter_value != std::cend(parser_state.var_id_to_values);
  $$ = found_value ? iter_value->second : std::nan("invalid-var-id");
  spdlog::debug("[var_lookup] var_id {}", $1);
}

func_call: FUNC_START func_args FUNC_END {
  $$ = 42.5f;
  spdlog::debug("[func_call] func_id {} args ({})",
    $1,
    fmt::join($2, ","));
}

func_args: %empty { $$ = {}; }
         | func_args FUNC_ARG { $$ = $1; $$.emplace_back($2); }

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
  constexpr auto func_arg_hash = shash("func_arg");
  constexpr auto func_end_hash = shash("func_end");
  constexpr auto var_lookup_hash = shash("var_lookup");
  const auto opcode_hash = shash(current.at("opcode").get<std::string>().c_str());

  switch (opcode_hash) {
    case func_start_hash:
      return parser::make_FUNC_START(current.at("func_id").get<FuncId>());
    case func_arg_hash:
      return parser::make_FUNC_ARG(current.at("var_id").get<VarId>());
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

  assembly::parser parser(lex_state, parser_state);

#if YYDEBUG
  parser.set_debug_stream(std::cout);
  parser.set_debug_level(1);
#endif

  try {
    const auto parsing_err = parser();
    if (parsing_err)
      return {};
    return parser_state.result_value;
  } catch (nlohmann::json::exception& exc) {
    spdlog::error("ASM JSON ERROR {}", exc.what());
    return {};
  }
}
