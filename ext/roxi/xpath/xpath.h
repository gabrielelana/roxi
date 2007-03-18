void yyerror(char* message); 
int xpath_yyinput(char* buffer, int needed_chars);
int xpath_yyparse(char* input_pointer, int input_length);
