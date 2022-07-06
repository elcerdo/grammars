%language "c++"
%require "3.2"
%skeleton "lalr1.cc"
%define api.token.constructor
%define api.value.type variant

%{

#include <iostream>
#include <vector>

// Print a list of strings.
auto operator<<(
  std::ostream& o,
  const std::vector<int>& ss)
  -> std::ostream&
{
  o << '[';

  bool first = true;
  for (const auto& s: ss) {
    if (!first) o << ", ";
    o << s;
    first = false;
  }

  return o << ']';
}

struct InputState {
  size_t position = 0;
  const size_t position_max = 0;
};

%}

%param {InputState& in_state}


%code
{
  namespace yy
  {
    // Return the next token.
    auto yylex(InputState& in_state) -> parser::symbol_type;
  }
}

%token END 0
%token <int> NUMBER
%nterm <std::vector<int>> list;
%nterm <int> item;

%% /* Grammar rules and actions follow */

result: list    { std::cout << "!!!! " << $1 << std::endl; }
;


list: %empty    { $$ = {}; }
    | list item { $$ = $1; $$.emplace_back($2); }
;

item: NUMBER
;

%%

auto yy::yylex(InputState& in_state) -> parser::symbol_type
{
  size_t stage = in_state.position++;
  return
    stage < in_state.position_max ? parser::make_NUMBER(static_cast<int>(stage)) :
    parser::make_END();
}

auto yy::parser::error(const std::string& msg) -> void
{
  std::cerr << "ERROR " << msg << std::endl;
}

#include <assembly.h>

int run_asm_parser(size_t nn)
{
  InputState in_state {
    0,
    nn,
  };
  yy::parser parse(in_state);
  return parse();
}

