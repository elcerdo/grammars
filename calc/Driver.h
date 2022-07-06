#pragma once

#include <string>
#include <unordered_map>

//#include <calc/parser.h>

//#define YY_DECL yy::parser::symbol_type yylex(driver& drv);
//YY_DECL;

// Conducting the whole scanning and parsing of Calc++.
struct Driver
{
	Driver();

  std::unordered_map<std::string, int> variables;
  int result;

	// Run the parser on file F.  Return 0 on success.
  int parse (const std::string& f);
  // The name of the file being parsed.
  std::string file;
  // Whether to generate parser debug traces.
  bool trace_parsing;

	// Handling the scanner.
  void scan_begin ();
  void scan_end ();
  // Whether to generate scanner debug traces.
  bool trace_scanning;
  // The token's location used by the scanner.
 //  yy::location location;
};