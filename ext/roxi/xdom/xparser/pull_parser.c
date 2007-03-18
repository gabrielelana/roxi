#include "pull_parser.h"
#include "pull_tokenizer.h"


inline static void enter_state(pull_parser *parser, parser_state new_state) {
	rb_ary_push(parser->_internal_stack, INT2FIX(new_state));
}


inline static parser_state leave_state(pull_parser *parser) {
	return FIX2INT(rb_ary_pop(parser->_internal_stack));
}


inline static parser_state current_state(pull_parser *parser) {
	return FIX2INT(rb_ary_last(parser->_internal_stack));
}

void init_environment(void) {
	new_function = rb_intern("new");

	roxi_module = rb_const_get(rb_cObject, rb_intern("ROXI"));
	nil_class = rb_const_get(rb_cObject, rb_intern("NilClass"));
	false_class = rb_const_get(rb_cObject, rb_intern("FalseClass"));
	
	roxi_xtext_class = rb_const_get(roxi_module, rb_intern("XText"));
	roxi_xname_class = rb_const_get(roxi_module, rb_intern("XName"));
	roxi_xcdata_class = rb_const_get(roxi_module, rb_intern("XCData"));
	roxi_xelement_class = rb_const_get(roxi_module, rb_intern("XElement"));
	roxi_xcomment_class = rb_const_get(roxi_module, rb_intern("XComment"));
	roxi_xdocument_class = rb_const_get(roxi_module, rb_intern("XDocument"));
	roxi_xattribute_class = rb_const_get(roxi_module, rb_intern("XAttribute"));
	roxi_xnamespace_class = rb_const_get(roxi_module, rb_intern("XNamespace"));
	roxi_xdeclaration_class = rb_const_get(roxi_module, rb_intern("XDeclaration"));
	roxi_xinstruction_class = rb_const_get(roxi_module, rb_intern("XInstruction"));

	roxi_xsyntaxerror_class = rb_const_get(rb_cObject, rb_intern("XSyntaxError"));
}


void init_buffer(pull_parser *parser, VALUE data) {
	unicode_buffer *buffer = (unicode_buffer*) parser;
	parser->_internal_buffer = data;
	buffer->begin = RSTRING(data)->ptr;
	buffer->end = buffer->begin + RSTRING(data)->len;
	buffer->current = buffer->begin;
}


void init_state(pull_parser *parser) {
	parser->char_number = 0;
	parser->line_number = 1;
	parser->_internal_stack = rb_ary_new();
	enter_state(parser, DOCUMENT_CONTENT);
}


void init_parser(pull_parser *parser, VALUE data) {
	init_buffer(parser, data);
	init_state(parser);
}


inline bool has_more(unicode_buffer *buffer) {
	unicode_interval look_for_space;

	if (buffer->current >= buffer->end)
		return false;

	peek_while(is_xml_space, buffer, &look_for_space);
	return look_for_space.end < buffer->end;
}


static inline VALUE pull_qualified_name(pull_parser *parser, unicode_buffer *buffer) {
	unicode_interval name;
	scan_while(is_xml_name_char, buffer, &name);
	if (interval_length(&name) == 0)
		SYNTAX_ERROR(parser, "expected name");
	if (scan(":", buffer)) {
		unicode_interval prefix = name;
		scan_while(is_xml_name_char, buffer, &name);
		if (interval_length(&name) == 0)
			SYNTAX_ERROR(parser, "expected name after prefix");
		peek(" ", buffer);
		return rb_funcall(roxi_xname_class, new_function, 2, interval_to_rbstring(&prefix), interval_to_rbstring(&name));
	}
	peek(" ", buffer);
	return rb_funcall(roxi_xname_class, new_function, 2, rb_str_new2(""), interval_to_rbstring(&name));
}


static inline VALUE pull_attribute_value(pull_parser *parser, unicode_buffer *buffer) {
	VALUE attribute_value;

	skip_while(is_xml_space, buffer);
	if (!scan("=", buffer))
		SYNTAX_ERROR(parser, "expected '=' beetween name and value");
	skip_while(is_xml_space, buffer);

	if (scan("\"", buffer)) {
		unicode_interval value;
		scan_while_delimited(is_xml_char, "\"", buffer, &value);
		if (!scan("\"", buffer))
			SYNTAX_ERROR(parser, "expected '\"");
		attribute_value = interval_to_rbstring(&value);

	} else if (scan("'", buffer)) {
		unicode_interval value;
		scan_while_delimited(is_xml_char, "'", buffer, &value);
		if (!scan("'", buffer))
			SYNTAX_ERROR(parser, "expected ''");
		attribute_value = interval_to_rbstring(&value);

	} else {
		SYNTAX_ERROR(parser, "expected value after '='");
	}

	return attribute_value;
}


static inline VALUE pull_attribute(pull_parser *parser, unicode_buffer *buffer) {
	VALUE attribute_value;
	VALUE attribute_name;

	attribute_name = pull_qualified_name(parser, buffer);
	if (strcmp("xmlns", RSTRING(rb_iv_get(attribute_name, "@name"))->ptr) == 0) {
		attribute_value = pull_attribute_value(parser, buffer);
		return rb_funcall(roxi_xnamespace_class, new_function, 2, rb_iv_get(attribute_name, "@prefix"), attribute_value);
	}
	if (strcmp("xmlns", RSTRING(rb_iv_get(attribute_name, "@prefix"))->ptr) == 0) {
		attribute_value = pull_attribute_value(parser, buffer);
		return rb_funcall(roxi_xnamespace_class, new_function, 2, rb_iv_get(attribute_name, "@name"), attribute_value);
	}
	attribute_value = pull_attribute_value(parser, buffer);
	return rb_funcall(roxi_xattribute_class, new_function, 2, attribute_name, attribute_value);
}


static inline VALUE pull_element(pull_parser *parser, unicode_buffer *buffer) {
	skip_while(is_xml_space, buffer);
	return rb_funcall(roxi_xelement_class, new_function, 1, pull_qualified_name(parser, buffer));
}


static inline VALUE pull_comment(pull_parser *parser, unicode_buffer *buffer) {
	unicode_interval comment;
	scan_while_delimited(is_xml_char, "-->", buffer, &comment);
	scan("-->", buffer);
	return rb_funcall(roxi_xcomment_class, new_function, 1, interval_to_rbstring(&comment));
}


static inline VALUE pull_instruction(pull_parser *parser, unicode_buffer *buffer) {
	unicode_interval processor;
	unicode_interval content;
	scan_while(is_xml_name_char, buffer, &processor);
	if (interval_length(&processor) == 0)
		SYNTAX_ERROR(parser, "expected name");
	scan_while_delimited(is_xml_char, "?>", buffer, &content);
	scan("?>", buffer);
	return rb_funcall(roxi_xinstruction_class, new_function, 2,
			interval_to_rbstring(&processor), interval_to_rbstring(&content));
}


static inline VALUE pull_cdata(pull_parser *parser, unicode_buffer *buffer) {
	unicode_interval cdata;
	scan_while_delimited(is_xml_char, "]]>", buffer, &cdata);
	scan("]]>", buffer);
	return rb_funcall(roxi_xcdata_class, new_function, 1, interval_to_rbstring(&cdata));
}


static inline void pull_dtd(pull_parser *parser, unicode_buffer *buffer) {
	unicode_interval discarding;
	unicode_interval before_square_open;
	unicode_interval before_angle_close;

	peek_while_delimited(is_xml_char, "[", buffer, &before_square_open);
	peek_while_delimited(is_xml_char, ">", buffer, &before_angle_close);

	if (interval_length(&before_square_open) < interval_length(&before_angle_close)) {
		buffer->current = before_square_open.end + 1;
		scan_while_delimited(is_xml_char, "]", buffer, &discarding);
		scan_while_delimited(is_xml_char, ">", buffer, &discarding);
	} else {
		scan_while_delimited(is_xml_char, ">", buffer, &discarding);
	}
	if (!scan(">", buffer))
		SYNTAX_ERROR(parser, "expected '>'");
}


VALUE pull(pull_parser *parser) {

	pull_parser savepoint = *parser;
	pull_parser *workparser = &savepoint;
	unicode_buffer *workbuffer = (unicode_buffer*) &savepoint;
	
	while (true) {
		if (!has_more(workbuffer)) YIELD_NODE(parser, workparser, Qfalse);
		switch(current_state(workparser)) {
		case DOCUMENT_CONTENT:
			if (skip_while(is_xml_space, workbuffer)) {
				continue;
			} else if (scan("<?xml", workbuffer)) {
				enter_state(workparser, DECLARATION_HEADER);
				YIELD_NODE(parser, workparser, rb_funcall(roxi_xdeclaration_class, new_function, 0));
			} else if (scan("<!DOCTYPE", workbuffer)) {
				enter_state(workparser, DOCTYPE_CONTENT);
				continue;
			} else if (scan("<!--", workbuffer)) {
				YIELD_NODE(parser, workparser, pull_comment(workparser, workbuffer));
			} else if (scan("<?", workbuffer)) {
				YIELD_NODE(parser, workparser, pull_instruction(workparser, workbuffer));
			} else if (scan("<", workbuffer)) {
				VALUE element = pull_element(workparser, workbuffer);
				enter_state(workparser, ELEMENT_HEADER);
				YIELD_NODE(parser, workparser, element);
			} else {
				SYNTAX_ERROR(workparser, "unexpected input");
			}
			break;
		case DOCTYPE_CONTENT:
			pull_dtd(workparser, workbuffer);
			leave_state(workparser);
			break;
		case DECLARATION_HEADER:
			if (skip_while(is_xml_space, workbuffer)) {
				continue;
			} else if (scan("?>", workbuffer)) {
				leave_state(workparser);
				YIELD_NODE(parser, workparser, Qnil);
			} else {
				YIELD_NODE(parser, workparser, pull_attribute(workparser, workbuffer));
			}
			break;
		case ELEMENT_HEADER:
			if (skip_while(is_xml_space, workbuffer)) {
				continue;
			} else if (scan("/>", workbuffer)) {
				leave_state(workparser);
				YIELD_NODE(parser, workparser, Qnil);
			} else if (scan(">", workbuffer)) {
				leave_state(workparser);
				enter_state(workparser, ELEMENT_CONTENT);
				continue;
			} else {
				YIELD_NODE(parser, workparser, pull_attribute(workparser, workbuffer));
			}
			break;
		case ELEMENT_CONTENT:
			if (scan("</", workbuffer)) {
				skip_while(is_xml_space, workbuffer);
				pull_qualified_name(workparser, workbuffer);
				skip_while(is_xml_space, workbuffer);
				if (!scan(">", workbuffer))
					SYNTAX_ERROR(workparser, "expected '>'");
				leave_state(workparser);
				YIELD_NODE(parser, workparser, Qnil);
			} else if (scan("<!--", workbuffer)) {
				YIELD_NODE(parser, workparser, pull_comment(workparser, workbuffer));
			} else if (scan("<![CDATA[", workbuffer)) {
				YIELD_NODE(parser, workparser, pull_cdata(workparser, workbuffer));
			} else if (scan("<?", workbuffer)) {
				YIELD_NODE(parser, workparser, pull_instruction(workparser, workbuffer));
			} else if (scan("<", workbuffer)) {
				VALUE element = pull_element(workparser, workbuffer);
				enter_state(workparser, ELEMENT_HEADER);
				YIELD_NODE(parser, workparser, element);
			} else {
				unicode_interval space;
				unicode_interval text;
				scan_while_delimited(is_xml_space, "<", workbuffer, &space);
				if (peek("<", workbuffer))
					continue;
				scan_while_delimited(is_xml_char, "<", workbuffer, &text);
				text.begin = space.begin;
				YIELD_NODE(parser, workparser, rb_funcall(roxi_xtext_class, new_function, 1, interval_to_rbstring(&text)));
			}
			break;
		}
	}
}


VALUE build(pull_parser *parser, VALUE root) {
	VALUE pulled;
	VALUE pulled_class;
	VALUE stack = rb_ary_new();
	VALUE current = (NIL_P(root)) ? rb_funcall(roxi_xdocument_class, new_function, 0) : root;
	rb_gc_register_address(&stack);
	if (!has_more((unicode_buffer*)parser)) return current;
	while (true) {
		pulled = pull(parser);
		rb_iv_set(pulled, "@parent", current);
		pulled_class = CLASS_OF(pulled);
		if (pulled_class == roxi_xelement_class) {
			rb_ary_push(rb_iv_get(current, "@children"), pulled);
			rb_ary_push(stack, current);
			current = pulled;
		} else if (pulled_class == roxi_xattribute_class) {
			if (CLASS_OF(current) == roxi_xdeclaration_class) {
				rb_funcall(current, rb_intern("add"), 1, pulled);
			} else {
				rb_ary_push(rb_iv_get(current, "@attributes"), pulled);
			}
		} else if (pulled_class == roxi_xnamespace_class) {
			rb_ary_push(rb_iv_get(current, "@namespaces"), pulled);
		} else if (pulled_class == roxi_xdeclaration_class) {
			rb_iv_set(current, "@declaration", pulled);
			rb_ary_push(stack, current);
			current = pulled;
		} else if (pulled_class == nil_class) {
			current = rb_ary_pop(stack);
		} else if (pulled_class == false_class) {
			break;
		} else {
			rb_ary_push(rb_iv_get(current, "@children"), pulled);
		}
	}
	rb_gc_unregister_address(&stack);
	return current;
}
