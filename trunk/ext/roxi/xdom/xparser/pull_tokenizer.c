#include "pull_parser.h"
#include "unicode.h"


bool is_xml_char(unicode c) {
	if (c < 0)
		return false;
	else if (c < 0x10000)
		return unicode_map[c] & UNICODE_XML_CHAR;
	else
		return (c <= 0x10ffff);
}

bool is_xml_letter(unicode c) {
	if (c < 0 || c > 0xffff)
		return false;
	return unicode_map[c] & UNICODE_XML_LETTER;
}

bool is_xml_name_char(unicode c) {
	if (c < 0 || c > 0xffff)
		return false;
	return unicode_map[c] & UNICODE_XML_NAME_CHAR;
}

bool is_xml_space(unicode c) {
	return unicode_map[c] & UNICODE_XML_SPACE;
}


static inline void next_unicode_char(unicode_buffer *buffer, unicode *next, int *nob) {
	pull_parser *parser = (pull_parser*) buffer;
	const byte *current = buffer->current;
	byte first;

	if (*current == 0)
		SYNTAX_ERROR(parser, "malformed utf8 character");

	if (*current < 0x80) {
		*nob = 1;
		*next = *current;

	} else if (*current < 0xc2) {
		SYNTAX_ERROR(parser, "malformed utf8 character");

	} else if (*current < 0xe0) {
		*nob = 2;
		*next = (*current++ & 0x1f) << 6;
		if (*current < 0x80 || *current > 0xbf)
			SYNTAX_ERROR(parser, "malformed utf8 character");
		*next |= *current & 0x3f;

	} else if (*current < 0xf0) {
		*nob = 3;
		
		first = *current;
		*next = (*current++ & 0x0f) << 12;

		if ((first == 0xe0 && (*current < 0xa0 || *current > 0xbf)) ||
		(first <  0xed && (*current < 0x80 || *current > 0xbf)) ||
		(first == 0xed && (*current < 0x80 || *current > 0x9f)) ||
		(first  > 0xed && (*current < 0x80 || *current > 0xbf)))
			SYNTAX_ERROR(parser, "malformed utf8 character");
		*next |= (*current++ & 0x3f) << 6;

		if (*current < 0x80 || *current > 0xbf)
			SYNTAX_ERROR(parser, "malformed utf8 character");
		*next |= *current & 0x3f;

	} else if (*current < 0xf5) {
		*nob = 4;

		first = *current;
		*next = (*current++ & 0x07) << 18;

		if ((first == 0xf0 && (*current < 0x90 || *current > 0xbf)) ||
		(first <  0xf4 && (*current < 0x80 || *current > 0xbf)) ||
		(first >= 0xf4 && (*current < 0x80 || *current > 0x8f)))
			SYNTAX_ERROR(parser, "malformed utf8 character");
		*next |= (*current++ & 0x3f) << 12;

		if (*current < 0x80 || *current > 0xbf)
			SYNTAX_ERROR(parser, "malformed utf8 character");
		*next |= (*current++ & 0x3f) << 6;

		if (*current < 0x80 || *current > 0xbf)
			SYNTAX_ERROR(parser, "malformed utf8 character");
		*next |= *current++ & 0x3f;

	} else {
		SYNTAX_ERROR(parser, "malformed utf8 character");

	}

}


static inline void next_position(pull_parser *parser, unicode next) {
	if (next == 10) {
		parser->line_number++;
		parser->char_number = 0;
	} else {
		parser->char_number++;
	}
}


inline int skip_while(bool(*match)(unicode), unicode_buffer *buffer) {
	pull_parser *parser = (pull_parser*) buffer;
	unicode_interval interval;
	interval.begin = buffer->current;
	{	int nob = 0;
		unicode next = 0;
		while(next_unicode_char(buffer, &next, &nob), match(next)) {
			next_position(parser, next);
			buffer->current += nob;
			if (buffer->current >= buffer->end)
				break;
		}
	}
	interval.end = buffer->current;
	return interval.end - interval.begin;
}


inline unicode_interval* scan_while(bool(*match)(unicode), unicode_buffer *buffer, unicode_interval *interval) {
	pull_parser *parser = (pull_parser*) buffer;
	interval->begin = buffer->current;
	{	int nob = 0;
		unicode next = 0;
		while(next_unicode_char(buffer, &next, &nob), match(next)) {
			next_position(parser, next);
			buffer->current += nob;
			if (buffer->current >= buffer->end)
				break;
		}
	}
	interval->end = buffer->current;
	return interval;
}


inline unicode_interval* peek_while(bool(*match)(unicode), unicode_buffer *buffer, unicode_interval *interval) {
	pull_parser fake_parser = *(pull_parser*)buffer;
	unicode_buffer *fake_buffer = &fake_parser.buffer;
	interval->begin = buffer->current;
	{	int nob = 0;
		unicode next = 0;
		while(next_unicode_char(fake_buffer, &next, &nob), match(next)) {
			fake_buffer->current += nob;
			if (fake_buffer->current >= buffer->end)
				break;
		}
	}
	interval->end = fake_buffer->current;
	return interval;
}

inline bool peek(const byte *expected, unicode_buffer *buffer) {
	pull_parser *parser = (pull_parser*) buffer;
	const byte *current_expected;
	const byte *current_given;
	for (current_expected = expected, current_given = buffer->current; *current_expected != 0; current_expected++, current_given++) {
		if (current_given >= buffer->end)
			SYNTAX_ERROR(parser, "unexpected end of input while scanning");
		if (*current_expected != *current_given)
			return false;
	}
	return true;
}


inline bool scan(const byte *expected, unicode_buffer *buffer) {
	pull_parser *parser = (pull_parser*) buffer;
	const byte *current_expected;
	const byte *current_given;
	for (current_expected = expected, current_given = buffer->current; *current_expected != 0; current_expected++, current_given++) {
		if (current_given >= buffer->end)
			SYNTAX_ERROR(parser, "unexpected end of input while scanning");
		if (*current_expected != *current_given)
			return false;
	}
	for (current_expected = expected; *current_expected != 0; current_expected++)
		next_position(parser, *current_expected);
	buffer->current = current_given;
	return true;
}


inline unicode_interval* peek_while_delimited(bool(*match)(unicode), const byte *delimiter, unicode_buffer *buffer, unicode_interval *interval) {
	pull_parser fake_parser = *(pull_parser*)buffer;
	unicode_buffer *fake_buffer = &fake_parser.buffer;
	interval->begin = buffer->current;
	{	int nob = 0;
		unicode next = 0;
		while(next_unicode_char(fake_buffer, &next, &nob), match(next)) {
			if (peek(delimiter, fake_buffer))
				break;
			fake_buffer->current += nob;
			if (fake_buffer->current >= buffer->end)
				break;
		}
	}
	interval->end = fake_buffer->current;
	return interval;
}


inline unicode_interval* scan_while_delimited(bool(*match)(unicode), const byte *delimiter, unicode_buffer *buffer, unicode_interval *interval) {
	pull_parser *parser = (pull_parser*) buffer;
	interval->begin = buffer->current;
	{	int nob = 0;
		unicode next = 0;
		while(next_unicode_char(buffer, &next, &nob), match(next)) {
			if (peek(delimiter, buffer))
				break;
			next_position(parser, next);
			buffer->current += nob;
			if (buffer->current >= buffer->end)
				break;
		}
	}
	interval->end = buffer->current;
	return interval;
}


inline size_t interval_length(unicode_interval *interval) {
	return interval->end - interval->begin;
}


inline VALUE interval_to_rbstring(unicode_interval *interval) {
	return rb_str_new(interval->begin, interval_length(interval));
}


void interval_inspect(unicode_interval *interval) {
	const byte *index;
	printf("interval [");
	for (index = interval->begin; index < interval->end; index++)
		iscntrl(*index) ? printf("_%d_", *index) : printf("%c", *index);
	printf("]\n");
}
