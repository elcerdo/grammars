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

struct LexerState {
  using Container = std::vector<nlohmann::json>;
  Container::const_iterator input_current;
  Container::const_iterator input_end;
};

struct ParserState {
  size_t result_count = 0;
};

using FuncId = size_t;
using VarId = std::string;

%}

%parse-param {LexerState& in_state} {ParserState& out_state}
%lex-param {LexerState& in_state}

%code
{
  namespace assembly
  {
    // Return the next token.
    auto yylex(LexerState& in_state) -> parser::symbol_type;
  }
}

%token END 0
%token<FuncId> FUNC_START
%token<VarId> FUNC_ARG
%token FUNC_END

%nterm<std::vector<VarId>> func_args

%start result

%% /* Grammar rules and actions follow */

result: func_call {
  out_state.result_count ++;
  spdlog::info("[result] result_count {}", out_state.result_count);
}

func_call: FUNC_START func_args FUNC_END {
  spdlog::info("[func_call] func_id {} args ({})",
    $1,
    fmt::join($2, ","));
}

func_args: %empty { $$ = {}; }
         | func_args FUNC_ARG { $$ = $1; $$.emplace_back($2); }

/* list  : %empty      { $$ = {}; }
      | list NUMBER { $$ = $1; $$.emplace_back($2); }
      | list FIZZ { $$ = $1; spdlog::info("FIZZ"); }
      | list BUZZ { $$ = $1; spdlog::info("BUZZ"); } */

%% /* Other definitions */

constexpr size_t shash(char const * ii)
{
  size_t seed = 0xa578ffb2;
  while (*ii != 0)
    seed ^= static_cast<size_t>(*ii++) + 0x9e3779b9 + (seed<<6) + (seed>>2);
  return seed;
}

const

auto assembly::yylex(LexerState& in_state) -> parser::symbol_type
{
  if (in_state.input_current >= in_state.input_end)
    return parser::make_END();

  const auto& current = *in_state.input_current++;

  constexpr auto func_start_hash = shash("func_start");
  constexpr auto func_arg_hash = shash("func_arg");
  constexpr auto func_end_hash = shash("func_end");
  const auto opcode_hash = shash(current.at("opcode").get<std::string>().c_str());

  switch (opcode_hash) {
    case func_start_hash:
      return parser::make_FUNC_START(current.at("func_id").get<FuncId>());
    case func_arg_hash:
      return parser::make_FUNC_ARG(current.at("var_id").get<VarId>());
    case func_end_hash:
      return parser::make_FUNC_END();
    default:
      assert(false);
      return parser::make_END();
  }
}

auto assembly::parser::error(const std::string& msg) -> void
{
  spdlog::error("ASM PARSER ERROR {}", msg);
}

auto assembly::run_parser(const nlohmann::json& jj) -> std::optional<size_t>
{
  if (!jj.is_array())
    return {};

  const auto kk = jj.get<LexerState::Container>();
  spdlog::debug("kk {}", kk.size());
  LexerState in_state {
    std::cbegin(kk),
    std::cend(kk),
  };

  ParserState output_state;

  assembly::parser parser(in_state, output_state);

#if YYDEBUG
  parser.set_debug_stream(std::cout);
  parser.set_debug_level(1);
#endif

  try {
    const auto parsing_err = parser();

    spdlog::debug("result_count {}", output_state.result_count);

    if (parsing_err)
      return {};
    return 42;
  } catch (nlohmann::json::exception& exc) {
    spdlog::error("ASM JSON ERROR {}", exc.what());
    return {};
  }
}
