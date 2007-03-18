#include "ruby.h"

#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include <ctype.h>

VALUE nil_class;
VALUE roxi_module;
VALUE false_class;
VALUE new_function;

VALUE roxi_xtext_class;
VALUE roxi_xname_class;
VALUE roxi_xcdata_class;
VALUE roxi_xelement_class;
VALUE roxi_xcomment_class;
VALUE roxi_xdocument_class;
VALUE roxi_xattribute_class;
VALUE roxi_xnamespace_class;
VALUE roxi_xdeclaration_class;
VALUE roxi_xinstruction_class;
VALUE roxi_xsyntaxerror_class;

#define rb_ary_last(ary) \
	((RARRAY(ary)->len==0) ? Qnil : (RARRAY(ary)->ptr[RARRAY(ary)->len-1]))

#define SYNTAX_ERROR(parser, message) \
	{	char error[256] = { 0 }; \
		sprintf(error, "[%d:%d] %s", \
				parser->line_number, \
				parser->char_number, \
				message \
		); \
		rb_raise(roxi_xsyntaxerror_class, error); \
	}

#define YIELD_NODE(parser, workpaser, node) \
	{	VALUE result = (node); \
		*parser = *workparser; \
		return result; \
	}

typedef unsigned char byte;
typedef unsigned int unicode;

typedef struct _unicode_interval {
	const byte *begin;
	const byte *end;
} unicode_interval;

typedef struct _unicode_buffer {
	const byte *begin;
	const byte *end;
	const byte *current;
} unicode_buffer;

typedef struct _pull_parser {
	unicode_buffer buffer;
	VALUE _internal_buffer;
	VALUE _internal_stack;
	int char_number;
	int line_number;
} pull_parser;

typedef enum _parser_state {
	DOCTYPE_CONTENT,
	DECLARATION_HEADER,
	DOCUMENT_CONTENT,
	ELEMENT_HEADER,
	ELEMENT_CONTENT
} parser_state;
