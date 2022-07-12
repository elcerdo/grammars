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

/*using NullaryFunctor = std::function<Scalar()>;
using UnaryFunctor = std::function<Scalar(Scalar)>;
using BinaryFunctor = std::function<Scalar(Scalar, Scalar)>;
using AnyFunctor = std::variant<NullaryFunctor, UnaryFunctor, BinaryFunctor>;

using VarIdToScalars = std::unordered_map<VarId, Scalar>;
using FuncIdToAnyFunctors = std::unordered_map<FuncId, AnyFunctor>; */


using LexerState = std::unique_ptr<std::string>;

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
%token PAREN_OPEN COMMA PAREN_CLOSE SEMICOLON BRACKET_OPEN BRACKET_CLOSE RETURN EQUAL
%left PLUS
%left MUL
%token<IdentId> IDENTIFIER
/* %token<FuncId> FUNC_START
%token FUNC_END
%token<VarId> VAR_LOOKUP*/

%nterm<FuncArg> func_arg
%nterm<FuncArgs> func_args func_extra_args
%nterm<IdentId> func_proto func_impl_open
%nterm<size_t> statements
%nterm<Graph::Node> expr
/*%nterm<Scalar> expr func_call var_lookup
%nterm<std::vector<Scalar>> func_args */

%start result

%% /* Grammar rules and actions follow */

result: declarations

declarations: %empty
            | declarations declaration

declaration: SEMICOLON
           | func_proto SEMICOLON
           | func_impl

func_impl: func_impl_open statements BRACKET_CLOSE
{
  assert(parser_state);
  const auto& func_protos = parser_state->func_protos;
  const auto& graph = parser_state->graph;
  const auto& node_to_func_args = parser_state->node_to_func_args;
  const auto& ret_node = parser_state->ret_node;

  spdlog::debug("[func_impl] identifier \"{}\" num_statements {} has_ret_node {}",
    $1,
    $2,
    graph.valid(ret_node));

  if (!graph.valid(ret_node))
    throw syntax_error("invalid ret node");

  const auto iter_proto = func_protos.find($1);
  if (iter_proto == std::cend(func_protos))
    throw syntax_error("unknown prototype");

  assert(iter_proto != std::cend(func_protos));
  const auto& [ret_type, args] = iter_proto->second;

  assert(graph.valid(ret_node));
  const auto& [ret_type_, ret_name] = node_to_func_args[ret_node];

  if (ret_type_ != ret_type)
    throw syntax_error("invalid return type");
}

func_impl_open: func_proto BRACKET_OPEN
{
  assert(parser_state);
  const auto& func_protos = parser_state->func_protos;
  auto& graph = parser_state->graph;
  auto& node_to_func_args = parser_state->node_to_func_args;
  auto& ret_node = parser_state->ret_node;
  auto& defined_vars = parser_state->defined_vars;

  spdlog::debug("[scope_open] identifier \"{}\"", $1);

  const auto iter_proto = func_protos.find($1);
  if (iter_proto == std::cend(func_protos))
    throw syntax_error("unknown prototype");

  assert(iter_proto != std::cend(func_protos));
  const auto& [ret_type, args] = iter_proto->second;

  spdlog::debug("[scope_open] ret_type {} nargs {}",
    ret_type,
    args.size());

  graph.clear();
  defined_vars.clear();
  ret_node = lemon::INVALID;

  for (const auto& arg : args) {
    const auto node = graph.addNode();
    node_to_func_args[node] = arg;
    const auto ret = defined_vars.emplace(std::get<1>(arg), node);
    assert(std::get<1>(ret));
  }

  $$ = $1;
}

statements: %empty { $$ = 0; }
          | statements statement { $$ = $1; $$++; }

statement: SEMICOLON
         | RETURN expr SEMICOLON
{
  assert(parser_state);
  const auto& graph = parser_state->graph;
  auto& ret_node = parser_state->ret_node;

  if (graph.valid(ret_node))
    throw syntax_error("multiple return");

  ret_node = $2;
}
         | TYPE IDENTIFIER EQUAL expr SEMICOLON
{
  assert(parser_state);
  auto& defined_vars = parser_state->defined_vars;

  const auto iter_var = defined_vars.find($2);
  if (iter_var != std::cend(defined_vars))
    throw syntax_error("variable already defined");

  const auto ret = defined_vars.emplace($2, $4);
  assert(std::get<1>(ret));
}

expr: IDENTIFIER
{
  spdlog::debug("[expr] var_lookup \"{}\"", $1);

  assert(parser_state);
  const auto& graph = parser_state->graph;
  const auto& node_to_func_args = parser_state->node_to_func_args;
  const auto& defined_vars = parser_state->defined_vars;

  const auto iter_var = defined_vars.find($1);
  if (iter_var == std::cend(defined_vars))
    throw syntax_error("unknown variable");

  assert(iter_var != std::cend(defined_vars));
  const auto node = iter_var->second;
  assert(graph.valid(node));

  $$ = node;
}
    | expr PLUS expr
{
  spdlog::debug("[expr] addition");

  assert(parser_state);
  auto& graph = parser_state->graph;
  auto& node_to_func_args = parser_state->node_to_func_args;
  auto& arc_to_names = parser_state->arc_to_names;

  const auto nleft = $1;
  const auto nright = $3;
  const auto [left_type, left_name] = node_to_func_args[nleft];
  const auto [right_type, right_name] = node_to_func_args[nright];

  if (left_type != right_type)
    throw syntax_error("mismatching add types");

  assert(left_type == right_type);
  const auto node = graph.addNode();
  node_to_func_args[node] = {left_type, "ADD"};

  const auto aleft = graph.addArc(node, nleft);
  const auto aright = graph.addArc(node, nright);
  arc_to_names[aleft] = "left";
  arc_to_names[aright] = "right";

  $$ = node;
}
    | expr MUL expr
{
  spdlog::debug("[expr] multiplication");

  assert(parser_state);
  auto& graph = parser_state->graph;
  auto& node_to_func_args = parser_state->node_to_func_args;
  auto& arc_to_names = parser_state->arc_to_names;

  const auto nleft = $1;
  const auto nright = $3;
  const auto [left_type, left_name] = node_to_func_args[nleft];
  const auto [right_type, right_name] = node_to_func_args[nright];

  if (left_type != right_type)
    throw syntax_error("mismatching mul types");

  assert(left_type == right_type);
  const auto node = graph.addNode();
  node_to_func_args[node] = {left_type, "MUL"};

  const auto aleft = graph.addArc(node, nleft);
  const auto aright = graph.addArc(node, nright);
  arc_to_names[aleft] = "left";
  arc_to_names[aright] = "right";

  $$ = node;
}
    | PAREN_OPEN expr PAREN_CLOSE
{
spdlog::debug("[expr] parenthesis");

assert(parser_state);
auto& graph = parser_state->graph;
auto& node_to_func_args = parser_state->node_to_func_args;
auto& arc_to_names = parser_state->arc_to_names;

const auto node_ = $2;
const auto [type_, name_] = node_to_func_args[node_];

const auto node = graph.addNode();
node_to_func_args[node] = {type_, "PAR"};

const auto arc = graph.addArc(node, node_);
arc_to_names[arc] = "single";

$$ = node;
}

func_proto: TYPE IDENTIFIER PAREN_OPEN func_args PAREN_CLOSE {
  std::vector<std::string> func_args_;
  for (const auto& func_arg : $4)
    func_args_.emplace_back(fmt::format("({},{})",
      std::get<0>(func_arg),
      std::get<1>(func_arg)));
  spdlog::debug("[func_proto] type {} identifier \"{}\" args [{}]",
    $1,
    $2,
    fmt::join(func_args_, ", "));

  assert(parser_state);
  const auto ret = parser_state->func_protos.emplace($2, std::make_tuple($1, $4));
  if (!std::get<1>(ret))
    throw syntax_error("function already defined");

  $$ = $2;
}

func_args: %empty { $$ = {}; }
         | func_arg func_extra_args { $$ = $2; $$.emplace_front($1); }

func_extra_args: %empty { $$ = {}; }
               | func_extra_args COMMA func_arg { $$ = $1; $$.emplace_back($3); }

func_arg: TYPE IDENTIFIER { $$ = std::make_tuple($1, $2); }

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
  , node_to_func_args(graph)
  , arc_to_names(graph)
{
}

std::string exprtree::to_string(const TypeId type_id)
{
  switch (type_id) {
    case TypeId::Float: return "float";
    case TypeId::Vec2: return "vec2";
    default: return "??";
  }
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
  assert(lex_state);

  { // skip separators
    static const std::regex re_skip("^ +");
    const auto current = *lex_state;
    *lex_state = std::regex_replace(current, re_skip, "");
    spdlog::trace("   [skip] \"{}\" -> \"{}\"",
      current,
      *lex_state);
  }

  const auto advance_match = [&lex_state](const std::smatch& match) -> void {
    const auto current = *lex_state;
    *lex_state = match.suffix().str();
    spdlog::trace("[advance] \"{}\" -> \"{}\"",
      current,
      *lex_state);
  };
  const auto advance_tick = [&lex_state](const size_t nn) -> void {
    const auto current = *lex_state;
    lex_state->erase(0, nn);
    spdlog::trace("[advance] \"{}\" -> \"{}\"",
      current,
      *lex_state);
    assert(nn > 0);
  };

  const auto current = *lex_state;

  if (current.empty())
    return parser::make_END();

  { // single character
    const auto letter = current[0];
    switch (letter) {
      case '(': advance_tick(1); return parser::make_PAREN_OPEN();
      case ',': advance_tick(1); return parser::make_COMMA();
      case ')': advance_tick(1); return parser::make_PAREN_CLOSE();
      case ';': advance_tick(1); return parser::make_SEMICOLON();
      case '{': advance_tick(1); return parser::make_BRACKET_OPEN();
      case '}': advance_tick(1); return parser::make_BRACKET_CLOSE();
      case '+': advance_tick(1); return parser::make_PLUS();
      case '=': advance_tick(1); return parser::make_EQUAL();
      case '*': advance_tick(1); return parser::make_MUL();
      default: break;
    }
  }

  { // keyword
    static const std::regex re("^(return)");
    constexpr auto return_h = shash("return");
    std::smatch match;
    if (std::regex_search(current, match, re)) {
      const auto type_h = shash(match[1].str().c_str());
      advance_match(match);
      switch(type_h) {
        case return_h: return parser::make_RETURN();
        default: assert(false); return parser::make_END();
      }
    }
  }

  { // type
    static const std::regex re("^(float|vec2)");
    constexpr auto float_h = shash("float");
    constexpr auto vec2_h = shash("vec2");
    std::smatch match;
    if (std::regex_search(current, match, re)) {
      const auto type_h = shash(match[1].str().c_str());
      advance_match(match);
      switch(type_h) {
        case float_h: return parser::make_TYPE(TypeId::Float);
        case vec2_h: return parser::make_TYPE(TypeId::Vec2);
        default: assert(false); return parser::make_END();
      }
    }
  }

  { // identifier
    static const std::regex re("^[a-z]+");
    std::smatch match;
    if (std::regex_search(current, match, re)) {
      advance_match(match);
      return parser::make_IDENTIFIER(match[0]);
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
  static const std::regex re_clean("[\r\t\n]");
  auto lex_state = std::make_unique<std::string>(std::regex_replace(source, re_clean, " "));

  auto parser_state = std::make_unique<Payload>();
  assert(parser_state);
  assert(lex_state);

  /*parser_state.var_id_to_scalars["xx"] = xx_value;
  parser_state.func_id_to_functors[FuncId::Zero] = []() -> Scalar { return 0; };
  parser_state.func_id_to_functors[FuncId::One] = []() -> Scalar { return 1; };
  parser_state.func_id_to_functors[FuncId::TimesTwo] = [](const Scalar xx) -> Scalar { return 2 * xx; };
  parser_state.func_id_to_functors[FuncId::MinusOne] = [](const Scalar xx) -> Scalar { return xx - 1; };
  parser_state.func_id_to_functors[FuncId::Add] = [](const Scalar xx, const Scalar yy) -> Scalar { return xx + yy; };*/

  parser pp(lex_state, parser_state);

#if YYDEBUG
  pp.set_debug_stream(std::cout);
  pp.set_debug_level(1);
#endif

  const auto parsing_err = pp();

  spdlog::debug("[run_parser] parsing_err {} num_func_protos {}",
    parsing_err,
    parser_state->func_protos.size());

  for (const auto& [ident_id, data] : parser_state->func_protos) {
    const auto& [ret_type_id, func_args] = data;
    std::vector<std::string> foo;
    for (const auto& func_arg : func_args)
      foo.emplace_back(fmt::format("{} {}", std::get<0>(func_arg), std::get<1>(func_arg)));
    spdlog::debug("[run_parser] ** {} {}({});",
      ret_type_id,
      ident_id,
      fmt::join(foo, ", "));
  }

  { // dump graph
    using NodeIt = Graph::NodeIt;
    using ArcIt = Graph::ArcIt;
    using namespace lemon;

    assert(parser_state);
    const auto& graph = parser_state->graph;
    const auto& node_to_func_args = parser_state->node_to_func_args;
    const auto& arc_to_names = parser_state->arc_to_names;

    spdlog::debug("[run_parser] num_nodes {} num_arcs {}",
      countNodes(graph),
      countArcs(graph));

    for (NodeIt ni(graph); ni!=INVALID; ++ni) {
      const auto& [type, name] = node_to_func_args[ni];
      spdlog::debug("[run_parser] NN{:03d} {} \"{}\"",
        graph.id(ni),
        type,
        name);
    }

    for (ArcIt ai(graph); ai!=INVALID; ++ai) {
      const auto& name = arc_to_names[ai];
      spdlog::debug("[run_parser] AA{:03d} NN{:03d} -> NN{:03d} \"{}\"",
        graph.id(ai),
        graph.id(graph.source(ai)),
        graph.id(graph.target(ai)),
        name);
    }
  }

  if (parsing_err) return {};

  return parser_state;
}
