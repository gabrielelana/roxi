#include <math.h>
#include <string.h>
#include <stdarg.h>

#include "ruby.h"

char* to_identifier(char* string);
void raise_error(const char* message);
VALUE array_concat(VALUE head, VALUE tail);
VALUE array_push(VALUE array, VALUE item);
VALUE make_symbol(char* string);
VALUE make_string(char* string);
VALUE make_number(char* string);
VALUE make_array(int argc, ...);
