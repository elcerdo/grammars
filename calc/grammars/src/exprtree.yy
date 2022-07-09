%language "c++"
%require "3.2"
%skeleton "lalr1.cc"
%define api.namespace {exprtree}
%define api.token.constructor
%define api.value.type variant

%{

#include <exprtree.h>

#include <spdlog/spdlog.h>
// #include <spdlog/fmt/bundled/ranges.h>

#include <regex>
/*#include <vector>
#include <functional>
#include <unordered_map>
#include <variant>*/

template<class> inline constexpr bool always_false_v = false;

using exprtree::TypeId;
/*using VarId = std::string;
using Scalar = float;

using NullaryFunctor = std::function<Scalar()>;
using UnaryFunctor = std::function<Scalar(Scalar)>;
using BinaryFunctor = std::function<Scalar(Scalar, Scalar)>;
using AnyFunctor = std::variant<NullaryFunctor, UnaryFunctor, BinaryFunctor>;

using VarIdToScalars = std::unordered_map<VarId, Scalar>;
using FuncIdToAnyFunctors = std::unordered_map<FuncId, AnyFunctor>; */


struct LexerState {
  std::string current; // FIXME may get away with only using iterators
};

using ParserState = std::unique_ptr<exprtree::Payload>;

%}

%parse-param {LexerState& lex_state} {ParserState& parser_state}
%lex-param {LexerState& lex_state}

%code
{
  namespace exprtree
  {
    // Return the next token.
    auto yylex(LexerState& lex_state) -> parser::symbol_type;
  }
}

%token END 0
%token<TypeId> TYPE
%token SEP
/* %token<FuncId> FUNC_START
%token FUNC_END
%token<VarId> VAR_LOOKUP

%nterm<Scalar> expr func_call var_lookup
%nterm<std::vector<Scalar>> func_args */

%start result

%% /* Grammar rules and actions follow */

result: %empty
      | func_pro

func_pro: TYPE SEP { spdlog::info("[type] {}", $1); }

/*result: expr {
  parser_state.result_value = $1;
  spdlog::debug("[result] value {}",
    parser_state.result_value);
}

expr: func_call
    | var_lookup

var_lookup: VAR_LOOKUP {
  const auto iter_scalar = parser_state.var_id_to_scalars.find($1);
  if (iter_scalar == std::cend(parser_state.var_id_to_scalars))
    throw syntax_error("unknown var");
  assert(iter_scalar != std::cend(parser_state.var_id_to_scalars));
  spdlog::debug("[var_lookup] id {} value {}",
    $1,
    iter_scalar->second);
  $$ = iter_scalar->second;
}

func_call: FUNC_START func_args FUNC_END {
  const auto iter_functor = parser_state.func_id_to_functors.find($1);
  if (iter_functor == std::cend(parser_state.func_id_to_functors))
    throw syntax_error("unknown func");
  assert(iter_functor != std::cend(parser_state.func_id_to_functors));
  spdlog::debug("[func_call] func {} args ({})",
    $1,
    fmt::join($2, ","));

  const auto maybe_value = std::visit([&](auto&& ff) -> std::optional<Scalar> {
    using T = std::decay_t<decltype(ff)>;
    if constexpr (std::is_same<T, NullaryFunctor>::value) {
      if ($2.size() == 0)
        return ff();
      return {};
    } else if constexpr (std::is_same<T, UnaryFunctor>::value) {
      if ($2.size() == 1)
        return ff($2[0]);
      return {};
    } else if constexpr (std::is_same<T, BinaryFunctor>::value) {
      if ($2.size() == 2)
        return ff($2[0], $2[1]);
      return {};
    }
    else
      static_assert(always_false_v<T>, "non-exhaustive visitor!");
    return true;
  }, iter_functor->second);

  if (!maybe_value)
    throw syntax_error("wrong func call");

  spdlog::debug("[func_call] value {}",
    *maybe_value);

  assert(maybe_value);
  $$ = *maybe_value;
}

func_args: %empty { $$ = {}; }
         | func_args expr { $$ = $1; $$.emplace_back($2); }*/

%% /* Other definitions */

exprtree::Payload::Payload()
  : graph()
  , foobar(graph)
{
}

constexpr size_t shash(char const * ii)
{
  size_t seed = 0xa578ffb2;
  while (*ii != 0)
    seed ^= static_cast<size_t>(*ii++) + 0x9e3779b9 + (seed<<6) + (seed>>2);
  return seed;
}

auto exprtree::yylex(LexerState& lex_state) -> parser::symbol_type
{
  const auto current = lex_state.current;
  const auto advance = [&lex_state, &current](const std::smatch& match) {
    lex_state.current = match.suffix().str();
    spdlog::warn("[advance] \"{}\" -> \"{}\"",
      current,
      lex_state.current);
  };

  { // separator
    static const std::regex re("^ +");
    std::smatch match;
    if (std::regex_search(current, match, re)) {
      advance(match);
      return parser::make_SEP();
    }
  }

  { // type
    static const std::regex re("^(float|vec2)");
    constexpr auto float_h = shash("float");
    constexpr auto vec2_h = shash("vec2");
    std::smatch match;
    if (std::regex_search(current, match, re)) {
      const auto type_h = shash(match[1].str().c_str());
      advance(match);
      switch(type_h) {
        case float_h: return parser::make_TYPE(TypeId::Float);
        case vec2_h: return parser::make_TYPE(TypeId::Vec2);
        default: assert(false); return parser::make_END();
      }
    }
  }

  return parser::make_END();
}

auto exprtree::parser::error(const std::string& msg) -> void
{
  spdlog::debug("[parser_error] {}", msg);
}

auto exprtree::run_parser(const std::string& source) -> std::unique_ptr<Payload>
{
  LexerState lex_state {
    source,
  };

  auto parser_state = std::make_unique<Payload>();
  /*parser_state.var_id_to_scalars["xx"] = xx_value;
  parser_state.func_id_to_functors[FuncId::Zero] = []() -> Scalar { return 0; };
  parser_state.func_id_to_functors[FuncId::One] = []() -> Scalar { return 1; };
  parser_state.func_id_to_functors[FuncId::TimesTwo] = [](const Scalar xx) -> Scalar { return 2 * xx; };
  parser_state.func_id_to_functors[FuncId::MinusOne] = [](const Scalar xx) -> Scalar { return xx - 1; };
  parser_state.func_id_to_functors[FuncId::Add] = [](const Scalar xx, const Scalar yy) -> Scalar { return xx + yy; };*/

  exprtree::parser parser(lex_state, parser_state);

#if YYDEBUG
  parser.set_debug_stream(std::cout);
  parser.set_debug_level(1);
#endif

  const auto parsing_err = parser();
  spdlog::debug("[run_parser] parsing_err {}", parsing_err);
  if (parsing_err) return {};

  return parser_state;
}
