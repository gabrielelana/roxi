#include "parser.h"

char* to_identifier(char* string) {
	int index;
	for (index=0; string[index]; index++)
		if (string[index] == '-') string[index] = '_';
	return string;
}

void raise_error(const char* message) {
	rb_raise(rb_eSyntaxError, message);
}

VALUE array_concat(VALUE head, VALUE tail) {
	return rb_ary_concat(head, tail);
}

VALUE array_push(VALUE array, VALUE item) {
	return rb_ary_push(array, item);
}

VALUE make_symbol(char* string) {
	VALUE rb_symbol = ID2SYM(rb_intern(string));
	return rb_symbol;
}

VALUE make_number(char* string) {
	VALUE rb_float = rb_float_new(atof(string));
	free(string);
	return rb_float;
}

VALUE make_string(char* string) {
	VALUE rb_str = rb_str_new2(string);
	free(string);
	return rb_str;
}

VALUE make_array(int argc, ...) {
	int i;
	va_list argl;
	VALUE array = rb_ary_new();

	va_start(argl, argc);
	for (i=0; i<argc; i++) {
		rb_ary_push(array, va_arg(argl, VALUE));
	}
	va_end(argl);

	return array;
}

static VALUE m_initialize(VALUE self, VALUE string) {
	rb_check_type(string, T_STRING);
	rb_iv_set(self, "@expression", string);
	rb_iv_set(self, "@ast", Qnil);
	return self;
}

static VALUE m_parse(VALUE self) {
	VALUE expression = rb_iv_get(self, "@expression");
	VALUE ast = xpath_yyparse(RSTRING(expression)->ptr, RSTRING(expression)->len);
	rb_iv_set(self, "@ast", ast);
	return ast;
}

void Init_parser() {
	VALUE mROXI = rb_define_module("ROXI");
	VALUE mXPath = rb_define_module_under(mROXI, "XPath");
	VALUE cParser = rb_define_class_under(mXPath, "Parser", rb_cObject);
	rb_define_method(cParser, "initialize", m_initialize, 1);
	rb_define_method(cParser, "parse", m_parse, 0);
}
