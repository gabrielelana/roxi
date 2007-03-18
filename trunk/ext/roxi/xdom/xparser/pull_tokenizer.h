bool is_xml_char(unicode c);
bool is_xml_letter(unicode c);
bool is_xml_name_char(unicode c);
bool is_xml_space(unicode c);

inline int skip_while(bool(*match)(unicode), unicode_buffer *buffer);
inline unicode_interval* scan_while(bool(*match)(unicode), unicode_buffer *buffer, unicode_interval *interval);
inline unicode_interval* peek_while(bool(*match)(unicode), unicode_buffer *buffer, unicode_interval *interval);
inline bool peek(const byte *expected, unicode_buffer *buffer);
inline bool scan(const byte *expected, unicode_buffer *buffer);
inline unicode_interval* peek_while_delimited(bool(*match)(unicode), const byte *delimiter, unicode_buffer *buffer, unicode_interval *interval);
inline unicode_interval* scan_while_delimited(bool(*match)(unicode), const byte *delimiter, unicode_buffer *buffer, unicode_interval *interval);
inline size_t interval_length(unicode_interval *interval);
inline VALUE interval_to_rbstring(unicode_interval *interval);
