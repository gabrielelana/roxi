%{

#include "parser.h"

#include "xpath.h"
#include "xpath.tab.h"

#define min(a,b)  ( (a<b) ? (a):(b) )

VALUE make_descendant_or_self_step(void);

%}

%union {
	char* text;
	VALUE value;
}

%token <text> OR
%token <text> AND
%token <text> PLUS
%token <text> MINUS
%token <text> STAR
%token <text> DOLLAR
%token <text> DIV
%token <text> MOD
%token <text> AT
%token <text> PIPE
%token <text> COMMA
%token <text> SLASH
%token <text> COLON
%token <text> PAREN_LEFT
%token <text> PAREN_RIGHT
%token <text> BRACKET_LEFT
%token <text> BRACKET_RIGHT
%token <text> DOUBLE_COLON
%token <text> DOUBLE_SLASH
%token <text> UNDERSCORE
%token <text> EQUALITY
%token <text> RELATION
%token <text> NODE_TYPE
%token <text> ABBREVIATED_SELF
%token <text> ABBREVIATED_PARENT
%token <text> AXIS_NAME
%token <text> LITERAL
%token <text> NCNAME
%token <text> NUMBER
%token <text> EOI

%type <value> xpath
%type <value> expression
%type <value> or_expression
%type <value> and_expression
%type <value> equality_expression
%type <value> relational_expression
%type <value> additive_expression
%type <value> multiplicative_expression
%type <value> unary_expression
%type <value> union_expression
%type <value> path_expression
%type <value> filter_expression
%type <value> predicates
%type <value> predicate
%type <value> location_path
%type <value> absolute_location_path
%type <value> empty_absolute_location_path
%type <value> relative_location_path
%type <value> step
%type <value> abbreviated_step
%type <value> node_test
%type <value> name_test
%type <value> axis_specifier
%type <value> primary_expression
%type <value> function_call
%type <value> argument_list
%type <value> argument
%type <value> variable_reference

%nonassoc SLASH DOUBLE_SLASH
%nonassoc STAR

%%

xpath: expression EOI { return $1; }
	;
expression: or_expression
	;
or_expression: and_expression
	| or_expression OR and_expression { $$ = make_array(3, make_symbol("or"), $1, $3); }
	;
and_expression: equality_expression
	| and_expression AND equality_expression { $$ = make_array(3, make_symbol("and"), $1, $3); }
	;
equality_expression: relational_expression
	| equality_expression EQUALITY relational_expression {
		if (strcmp($2, "=") == 0) $$ = make_array(3, make_symbol("eq"), $1, $3);
		if (strcmp($2, "!=") == 0) $$ = make_array(3, make_symbol("neq"), $1, $3);
	}
	;
relational_expression: additive_expression
	| relational_expression RELATION additive_expression {
		if (strcmp($2, "<") == 0) $$ = make_array(3, make_symbol("lt"), $1, $3);
		if (strcmp($2, "<=") == 0) $$ = make_array(3, make_symbol("let"), $1, $3);
		if (strcmp($2, ">") == 0) $$ = make_array(3, make_symbol("gt"), $1, $3);
		if (strcmp($2, ">=") == 0) $$ = make_array(3, make_symbol("get"), $1, $3);
	}
	;
additive_expression: multiplicative_expression
	| additive_expression PLUS multiplicative_expression { $$ = make_array(3, make_symbol("add"), $1, $3); } 
	| additive_expression MINUS multiplicative_expression { $$ = make_array(3, make_symbol("sub"), $1, $3); }
	;
multiplicative_expression: unary_expression
	| multiplicative_expression STAR unary_expression { $$ = make_array(3, make_symbol("mul"), $1, $3); }
	| multiplicative_expression MOD unary_expression { $$ = make_array(3, make_symbol("mod"), $1, $3); }
	| multiplicative_expression DIV unary_expression { $$ = make_array(3, make_symbol("div"), $1, $3); }
	;
unary_expression: union_expression
	| MINUS unary_expression { $$ = make_array(2, make_symbol("neg"), $2); }
	;
union_expression: path_expression
	| union_expression PIPE path_expression { $$ = make_array(3, make_symbol("union"), $1, $3); }
	;
path_expression: location_path 
	| filter_expression { $$ = array_concat(make_array(1, make_symbol("filter")), $1); }
	| filter_expression SLASH relative_location_path { 
		VALUE expression = make_array(1, make_symbol("filter"));
		expression = array_concat(expression, $1);
		expression = array_concat(expression,
			make_array(1, $3));
		$$ = expression;
	}
	| filter_expression DOUBLE_SLASH relative_location_path {
		VALUE expression = make_array(1, make_symbol("filter"));
		expression = array_concat(expression, $1);
		expression = array_concat(expression,
			make_array(1, array_concat(make_descendant_or_self_step(), $3)));
		$$ = expression;
	}
	;
filter_expression: primary_expression { $$ = make_array(2, $1, make_array(0)); }
	| primary_expression predicates { $$ = make_array(2, $1, $2); }
	;
predicates: predicate { $$ = make_array(1, $1); }
	| predicates predicate { $$ = array_push($1, $2); }
	;
predicate: BRACKET_LEFT expression BRACKET_RIGHT { $$ = $2; }
	;
location_path: relative_location_path { $$ = make_array(2, make_symbol("relative"), $1); }
	| absolute_location_path { $$ = make_array(2, make_symbol("absolute"), $1); }
	;
absolute_location_path: SLASH relative_location_path { $$ = $2; }
	| DOUBLE_SLASH relative_location_path {
		$$ = array_concat(make_descendant_or_self_step(), $2);
	}
	| empty_absolute_location_path
	;
empty_absolute_location_path: SLASH { $$ = make_array(0); }
	| DOUBLE_SLASH { $$ = make_descendant_or_self_step(); }
	;
relative_location_path: step { $$ = make_array(1, $1); }
	| relative_location_path SLASH step { $$ = array_push($1, $3); }
	;
step: axis_specifier node_test predicates { $$ = make_array(3, $1, $2, $3); }
	| axis_specifier node_test { $$ = make_array(3, $1, $2, make_array(0)); }
	| node_test predicates { $$ = make_array(3, make_array(1, make_symbol("child")), $1, $2); }
	| node_test { $$ = make_array(3, make_array(1, make_symbol("child")), $1, make_array(0)); }
	| abbreviated_step { $$ = make_array(3, $1, make_array(1, make_symbol("node")), make_array(0)); }
	| abbreviated_step predicates { $$ = make_array(3, $1, make_array(1, make_symbol("node")), $2); }
	;
abbreviated_step: ABBREVIATED_SELF { $$ = make_array(1, make_symbol("self")); }
	| ABBREVIATED_PARENT { $$ = make_array(1, make_symbol("parent")) }
	;
node_test: name_test
	| NODE_TYPE PAREN_LEFT PAREN_RIGHT { $$ = make_array(1, make_symbol(to_identifier($1))); }
	| NODE_TYPE PAREN_LEFT LITERAL PAREN_RIGHT {
		if (strcmp($1, "node") == 0) yyerror("syntax error");
		$$ = make_array(2, make_symbol(to_identifier($1)), make_string($3));
	}
	;
name_test: STAR { $$ = make_array(1, make_symbol("all")); }
	| NCNAME { $$ = make_array(2, make_symbol("qname"), make_string($1)); }
	| AXIS_NAME { $$ = make_array(2, make_symbol("qname"), make_string($1)); }
	| NODE_TYPE { $$ = make_array(2, make_symbol("qname"), make_string($1)); }
	| NCNAME COLON STAR { $$ = make_array(2, make_symbol("prefix"), make_string($1)); }
	| NCNAME COLON NCNAME { $$ = make_array(3, make_symbol("qname"), make_string($3), make_string($1)); }
	| NCNAME COLON AXIS_NAME { $$ = make_array(3, make_symbol("qname"), make_string($3), make_string($1)); }
	| NCNAME COLON NODE_TYPE { $$ = make_array(3, make_symbol("qname"), make_string($3), make_string($1)); }
	;
axis_specifier: AT { $$ = make_array(1, make_symbol("attribute")); }
	| AXIS_NAME DOUBLE_COLON { $$ = make_array(1, make_symbol(to_identifier($1))); }
	;
primary_expression: variable_reference { $$ = make_array(2, make_symbol("variable"), $1); }
	| PAREN_LEFT expression PAREN_RIGHT { $$ = make_array(2, make_symbol("expression"), $2); }
	| LITERAL { $$ = make_array(2, make_symbol("literal"), make_string($1)); }
	| NUMBER { $$ = make_array(2, make_symbol("number"), make_number($1)); }
	| function_call
	;
function_call: NCNAME PAREN_LEFT PAREN_RIGHT { $$ = make_array(3, make_symbol("function"), make_string($1), make_array(0)); }
	| NCNAME PAREN_LEFT argument_list PAREN_RIGHT { $$ = make_array(3, make_symbol("function"), make_string($1), $3); }
	;
argument_list: argument { $$ = make_array(1, $1); }
	| argument_list COMMA argument { $$ = array_push($1, $3); }
	;
argument: expression
	;
variable_reference: DOLLAR NCNAME { $$ = make_string($2); }
	;

%%

static const char* input_buffer;
static void* input_end;
static void* input_start;

int xpath_yyparse(char* input_pointer, int input_length) {
	input_start = (void*) input_pointer;
	input_end = (void*) (input_pointer + input_length);
	return yyparse();
}

int xpath_yyinput(char* buffer, int needed_chars) {
	int available_chars = min(needed_chars, (input_end - input_start));
	if (available_chars > 0) {
		memcpy(buffer, input_start, available_chars);
		input_start += available_chars;
	}
	return available_chars;
}

void yyerror(char* message) {
	raise_error(message);
}

VALUE make_descendant_or_self_step(void) {
	make_array(1,
		make_array(3,
			make_array(1, make_symbol("descendant_or_self")),
			make_array(1, make_symbol("node")),
			make_array(0)
		)
	);
}
