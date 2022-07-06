%language "c++"
%require "3.2"
%skeleton "lalr1.cc"
%define api.namespace {assembly}
%define api.token.constructor
%define api.value.type variant

%{

#include <assembly.h>

#include <spdlog/spdlog.h>

#include <vector>
#include <iostream>
#include <sstream>

// Print a list of strings.
auto operator<<(
  std::ostream& o,
  const std::vector<int>& ss)
  -> std::ostream&
{
  o << "[";

  bool first = true;
  for (const auto& s: ss) {
    if (!first) o << ", ";
    o << s;
    first = false;
  }

  return o << "] (" << ss.size() << ")";
}

struct InputState {
  size_t position = 0;
  const size_t position_max = 0;
};

struct OutputState {
  size_t last_list_size = 0;
  size_t list_count = 0;
};

static OutputState output_state;

%}

%param {InputState& in_state}

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

  output_state.list_count ++;
  output_state.last_list_size = $$;

  std::stringstream ss;
  ss << $1;
  spdlog::info("!!!! {}", ss.str());
}
list  : %empty      { $$ = {}; }
      | list NUMBER { $$ = $1; $$.emplace_back($2); }
      | list FIZZ { $$ = $1; spdlog::info("FIZZ"); }
      | list BUZZ { $$ = $1; spdlog::info("BUZZ"); }

%% /* Other definitions */

auto assembly::yylex(InputState& in_state) -> parser::symbol_type
{
  const size_t pos = in_state.position++;
  return
    pos >= in_state.position_max ? parser::make_END() :
    pos % 3  == 0 ? parser::make_FIZZ() :
    pos % 5  == 0 ? parser::make_BUZZ() :
    parser::make_NUMBER(static_cast<int>(pos));
}

auto assembly::parser::error(const std::string& msg) -> void
{
  spdlog::error("ERROR {}", msg);
}

auto assembly::run_parser(const size_t nn) -> std::optional<size_t>
{
  InputState in_state {
    0,
    nn,
  };
  assembly::parser parser(in_state);
#if YYDEBUG
  parser.set_debug_stream(std::cout);
  parser.set_debug_level(1);
#endif
  spdlog::info("num_eval {}", output_state.list_count);
  if (parser())
    return {};
  return output_state.last_list_size;
}
