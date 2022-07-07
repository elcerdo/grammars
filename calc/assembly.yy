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

struct InputState {
  using Container = std::vector<nlohmann::json>;
  Container::const_iterator input_current;
  Container::const_iterator input_end;
};

struct OutputState {
  size_t last_list_size = 0;
  size_t list_count = 0;
};

%}

%parse-param {InputState& in_state} {OutputState& out_state}
%lex-param {InputState& in_state}

%code
{
  namespace assembly
  {
    // Return the next token.
    auto yylex(InputState& in_state) -> parser::symbol_type;
  }
}

%token END 0
%token FIZZ
%token BUZZ
%token<int> NUMBER

%type<size_t> result
%type<std::vector<int>> list

%start result

%% /* Grammar rules and actions follow */

result: list        {
  $$ = $1.size();

  out_state.list_count ++;
  out_state.last_list_size = $$;

  spdlog::info("!!!! [{}] ({})",
    fmt::join($1, ","),
    $1.size());
}

list  : %empty      { $$ = {}; }
      | list NUMBER { $$ = $1; $$.emplace_back($2); }
      | list FIZZ { $$ = $1; spdlog::info("FIZZ"); }
      | list BUZZ { $$ = $1; spdlog::info("BUZZ"); }

%% /* Other definitions */

auto assembly::yylex(InputState& in_state) -> parser::symbol_type
{
  if (in_state.input_current >= in_state.input_end)
    return parser::make_END();

  const auto& current = *in_state.input_current++;
  return parser::make_NUMBER(current.at("xx").get<int>());
}

auto assembly::parser::error(const std::string& msg) -> void
{
  spdlog::error("ASM ERROR {}", msg);
}

auto assembly::run_parser(const nlohmann::json& jj) -> std::optional<size_t>
{
  if (!jj.is_array())
    return {};

  const auto kk = jj.get<InputState::Container>();
  spdlog::debug("kk {}", kk.size());
  InputState in_state {
    std::cbegin(kk),
    std::cend(kk),
  };

  OutputState output_state;

  assembly::parser parser(in_state, output_state);

#if YYDEBUG
  parser.set_debug_stream(std::cout);
  parser.set_debug_level(1);
#endif

  try {
    const auto parsing_err = parser();

    spdlog::debug("num_eval {}", output_state.list_count);

    if (parsing_err)
      return {};
    return output_state.last_list_size;
  } catch (nlohmann::json::exception& exc) {
    return {};
  }
}
