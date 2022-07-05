%language "c++"
%require "3.2"
%skeleton "lalr1.cc"
%output "aaa.cc"
%defines "aaa.h"
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

using std::endl;

%}

%code
{
  namespace yy
  {
    // Return the next token.
    auto yylex() -> parser::symbol_type;
  }
}

%token END 0
%token <int> NUMBER
%nterm <std::vector<int>> list;
%nterm <int> item;

%% /* Grammar rules and actions follow */

result: list    { std::cout << "!!!! " << $1 << endl; }
;


list: %empty    { $$ = {}; }
    | list item { $$ = $1; $$.emplace_back($2); }
;

item: NUMBER
;

%%

auto yy::yylex() -> parser::symbol_type
{
  static int count = 0;
  int stage = count++;
  return stage > 10 ? parser::make_END() : parser::make_NUMBER(stage);
}

auto yy::parser::error(const std::string& msg) -> void
{
  std::cerr << "ERROR " << msg << endl;
}


int main(int argc, char* argv[])
{
  yy::parser parse;
  return parse();
}

