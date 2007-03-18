%{

#undef YY_INPUT
#define YY_INPUT(b, r, ms) (r = xpath_yyinput(b, ms))

#include <string.h>

#include "parser.h"
#include "xpath.tab.h"

extern int xpath_yyinput(char* buffer, int needed_chars);

int do_token(const char* buffer, int token, const char* message);

%}

LETTER [A-Za-z\x7F-\xFF]
DIGIT [0-9]
ALL [\x00-\xFF]
BLANK [\t\r\n ]

OR "or"
AND "and"
PLUS "+"
MINUS "-"
STAR "*"
DOLLAR "$"
DIV "div"
MOD "mod"

AT "@"
PIPE "|"
COMMA ","
SLASH "/"
COLON ":"
PAREN_LEFT "("
PAREN_RIGHT ")"
BRACKET_LEFT "["
BRACKET_RIGHT "]"
DOUBLE_COLON "::"
DOUBLE_SLASH "//"
UNDERSCORE "_"
EQUALITY "="|"!="
RELATION "<="|">="|"<"|">"

NODE_TYPE "comment"|"text"|"node"|"processing-instruction"
ABBREVIATED_SELF "."
ABBREVIATED_PARENT ".."

AXIS_NAME "ancestor"|"ancestor-or-self"|"attribute"|"child"|"descendant"|"descendant-or-self"|"following"|"following-sibling"|"namespace"|"parent"|"preceding"|"preceding-sibling"|"self"

NUMBER {DIGIT}+("."{DIGIT}+)?|"."{DIGIT}+
LITERAL "'"[^']*"'"|"\""[^"]*"\""
NCNAME ({LETTER}|"_")({LETTER}|"_"|{DIGIT}|"."|"-")*

%%

{NUMBER} { return do_token(yytext, NUMBER, "NUMBER"); }
{NODE_TYPE} { return do_token(yytext, NODE_TYPE, "NODE_TYPE"); }
{ABBREVIATED_SELF} { return do_token(yytext, ABBREVIATED_SELF, "ABBREVIATED_SELF"); }
{ABBREVIATED_PARENT} { return do_token(yytext, ABBREVIATED_PARENT, "ABBREVIATED_PARENT"); }
{AXIS_NAME} { return do_token(yytext, AXIS_NAME, "AXIS_NAME"); }
{LITERAL} { return do_trim(yytext, LITERAL, "LITERAL"); }

{OR} { return do_token(yytext, OR, "OR"); }
{AND} { return do_token(yytext, AND, "AND"); }
{PLUS} { return do_token(yytext, PLUS, "PLUS"); }
{MINUS} { return do_token(yytext, MINUS, "MINUS"); }
{STAR} { return do_token(yytext, STAR, "STAR"); }
{DOLLAR} { return do_token(yytext, DOLLAR, "DOLLAR"); }
{DIV} { return do_token(yytext, DIV, "DIV"); }
{MOD} { return do_token(yytext, MOD, "MOD"); }

{AT} { return do_token(yytext, AT, "AT"); }
{PIPE} { return do_token(yytext, PIPE, "PIPE"); }
{COMMA} { return do_token(yytext, COMMA, "COMMA"); }
{SLASH} { return do_token(yytext, SLASH, "SLASH"); }
{COLON} { return do_token(yytext, COLON, "COLON"); }

{PAREN_LEFT} { return do_token(yytext, PAREN_LEFT, "PAREN_LEFT"); }
{PAREN_RIGHT} { return do_token(yytext, PAREN_RIGHT, "PAREN_RIGHT"); }
{BRACKET_LEFT} { return do_token(yytext, BRACKET_LEFT, "BRACKET_LEFT"); }
{BRACKET_RIGHT} { return do_token(yytext, BRACKET_RIGHT, "BRACKET_RIGHT"); }

{DOUBLE_COLON} { return do_token(yytext, DOUBLE_COLON, "DOUBLE_COLON"); }
{DOUBLE_SLASH} { return do_token(yytext, DOUBLE_SLASH, "DOUBLE_SLASH"); }
{UNDERSCORE} { return do_token(yytext, UNDERSCORE, "UNDERSCORE"); }

{EQUALITY} { return do_token(yytext, EQUALITY, "EQUALITY"); }
{RELATION} { return do_token(yytext, RELATION, "RELATION"); }

{NCNAME} { return do_token(yytext, NCNAME, "NCNAME"); }

<<EOF>> { return do_token("", EOI, "EOI"); }

{BLANK} ;
.|\n ;

%%

int do_trim(const char* buffer, int token, const char* message) {
	int length = strlen(buffer)+1;
	char* trimmed = calloc(length-2, sizeof(char));
	strncpy(trimmed, buffer+1, length-3);
	yylval.text = trimmed;
	return token;
}

int do_token(const char* buffer, int token, const char* message) {
	yylval.text = strdup(yytext);
	return token;
}

int yywrap(void) {
	return 1;
}

