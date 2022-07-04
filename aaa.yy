%language "c++"
%require "3.2"
%define api.token.constructor
%define api.value.type variant

%{

#include <iostream>
#include <vector>


// Print a list of strings.
auto
operator<< (std::ostream& o, const std::vector<std::string>& ss)
  -> std::ostream&
{
  o << '{';
  const char *sep = "";

  for (const auto& s: ss)
    {
      o << sep << s;
      sep = ", ";
    }

  return o << '}';
}

%}

%token <int> NUMBER

%code
{
  namespace yy
  {
    // Return the next token.
    auto yylex() -> parser::symbol_type
    {
      static int count = 0;
      int stage = count++;
      return parser::make_NUMBER(stage);
    }

    // Report an error to the user.
    auto parser::error(const std::string& msg) -> void
    {
      std::cerr << msg << '\n';
    }
  }
}

%% /* Grammar rules and actions follow */

result:
  list  { std::cout << $1.size() << '\n'; }
;


%nterm <std::vector<std::string>> list;
list: %empty     { /* Generates an empty string list */ }
;

%% 

using std::cout;
using std::endl;



int main(int argc, char* argv[])
{
  return 0;
}

