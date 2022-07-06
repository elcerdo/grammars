%language "c++"
%require "3.2"
%skeleton "lalr1.cc"
%param {const size_t nn}
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
    auto yylex(const size_t nn) -> parser::symbol_type;
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

auto yy::yylex(const size_t nn) -> parser::symbol_type
{
  static size_t count = 0;
  size_t stage = count++;
  return
    stage < 10 ? parser::make_NUMBER(static_cast<int>(stage)) :
    parser::make_END();
}

auto yy::parser::error(const std::string& msg) -> void
{
  std::cerr << "ERROR " << msg << endl;
}


int foo(size_t nn)
{
  yy::parser parse(10);
  return parse();
}

