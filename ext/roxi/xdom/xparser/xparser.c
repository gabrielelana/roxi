#include "pull_parser.h"
#include "unicode.h"

#define rb_get_struct(obj, type) \
	(Check_Type(obj, T_DATA), (type*)DATA_PTR(obj))

static void mark_parser(pull_parser* parser) {
	rb_gc_mark(parser->_internal_buffer);
	rb_gc_mark(parser->_internal_stack);
}

static void free_parser(pull_parser* parser) {
	free(parser);
}

static VALUE new_parser(VALUE klass) {
	pull_parser *parser = malloc(sizeof(pull_parser));
	if (!parser) rb_raise(rb_eNoMemError, "unable to allocate xparser internal state");
	return Data_Wrap_Struct(klass, mark_parser, free_parser, parser);
}

static VALUE m_initialize(VALUE self, VALUE data) {
	pull_parser *parser = rb_get_struct(self, pull_parser);

	rb_gc_disable();
	init_environment();
	init_parser(parser, data);
	rb_gc_enable();

	rb_iv_set(self, "@current", Qnil);
	return self;
}

static VALUE m_rest(VALUE self) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	unicode_buffer *buffer = (unicode_buffer*) parser;
	return rb_str_new(buffer->current, buffer->end - buffer->current);
}

static VALUE m_pull(VALUE self) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	VALUE current = pull(parser);
	rb_iv_set(self, "@current", current);
	return current;
}

static VALUE m_build(int argc, VALUE *argv, VALUE self) {
	VALUE root = Qnil;
	pull_parser *parser = rb_get_struct(self, pull_parser);
	rb_scan_args(argc, argv, "01", &root);
	return build(parser, root);
}

static VALUE m_append(VALUE self, VALUE data) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	if (NIL_P(data)) return self;
	init_buffer(parser, rb_str_append(m_rest(self), data));
	return self;
}

static VALUE m_insert(VALUE self, VALUE data) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	if (NIL_P(data)) return self;
	init_buffer(parser, rb_str_append(data, m_rest(self)));
	return self;
}

static VALUE m_current(VALUE self) {
	return rb_iv_get(self, "@current");
}

static VALUE m_more(VALUE self) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	return has_more((unicode_buffer*)parser) ? Qtrue : Qfalse;
}

static VALUE m_rewind(VALUE self) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	parser->buffer.current = parser->buffer.begin;
	init_state(parser);
	return self;
}

static VALUE m_lineno(VALUE self) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	return INT2FIX(parser->line_number);
}

static VALUE m_charno(VALUE self) {
	pull_parser *parser = rb_get_struct(self, pull_parser);
	return INT2FIX(parser->char_number);
}

void Init_xparser() {
	VALUE mROXI = rb_define_module("ROXI");
	VALUE cXParser = rb_define_class_under(mROXI, "XParser", rb_cObject);
	VALUE eXSyntaxError = rb_define_class_under(mROXI, "XSyntaxError", rb_eStandardError);
	rb_define_alloc_func(cXParser, new_parser);
	rb_define_method(cXParser, "initialize", m_initialize, 1);
	rb_define_method(cXParser, "pull", m_pull, 0);
	rb_define_method(cXParser, "build", m_build, -1);
	rb_define_method(cXParser, "append", m_append, 1);
	rb_define_method(cXParser, "insert", m_insert, 1);
	rb_define_method(cXParser, "rest", m_rest, 0);
	rb_define_method(cXParser, "current", m_current, 0);
	rb_define_method(cXParser, "more?", m_more, 0);
	rb_define_method(cXParser, "rewind", m_rewind, 0);
	rb_define_method(cXParser, "lineno", m_lineno, 0);
	rb_define_method(cXParser, "charno", m_charno, 0);
}
