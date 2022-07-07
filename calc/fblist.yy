%language "c++"
%require "3.2"
%skeleton "lalr1.cc"
%define api.namespace {fblist}
%define api.token.constructor
%define api.value.type variant

%{

#include <fblist.h>

#include <spdlog/spdlog.h>
#include <spdlog/fmt/bundled/ranges.h>

#include <vector>

struct InputState {
  size_t position = 0;
  const size_t position_max = 0;
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
  namespace fblist
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

auto fblist::yylex(InputState& in_state) -> parser::symbol_type
{
  const size_t pos = in_state.position++;
  return
    pos >= in_state.position_max ? parser::make_END() :
    pos % 3  == 0 ? parser::make_FIZZ() :
    pos % 5  == 0 ? parser::make_BUZZ() :
    parser::make_NUMBER(static_cast<int>(pos));
}

auto fblist::parser::error(const std::string& msg) -> void
{
  spdlog::error("FBLIST ERROR {}", msg);
}

auto fblist::run_parser(const size_t nn) -> std::optional<size_t>
{
  InputState in_state {
    0,
    nn,
  };
  OutputState output_state;
  fblist::parser parser(in_state, output_state);
#if YYDEBUG
  parser.set_debug_stream(std::cout);
  parser.set_debug_level(1);
#endif
  const auto parsing_err = parser();
  spdlog::debug("num_eval {}", output_state.list_count);
  if (parsing_err)
    return {};
  return output_state.last_list_size;
}
