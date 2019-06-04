Definitions.

KEYWORDS=nil|true|false
SYMBOLS=[=\n]
WHITESPACE=[\s\t\r]+
STRING="([^\\"\n]|\\.)*"
KEY=[^="\s\t\r\n]+
NUM=[0-9]+
INDENT=(:\s)+

Rules.

{STRING}     : {token, {str, TokenLine, extract_string(TokenChars)}}.
{SYMBOLS}    : {token, {list_to_atom(TokenChars), TokenLine}}.
{INDENT}     : {token, {indent, TokenLine, {indent, TokenLen div 2}}}.
{NUM}\.{NUM} : {token, {float, TokenLine, list_to_float(TokenChars)}}.
{NUM}        : {token, {int, TokenLine, list_to_integer(TokenChars)}}.
{WHITESPACE} : {token, {whitespace, TokenLine, whitespace}}.
{KEYWORDS}   : {token, {list_to_atom(TokenChars), TokenLine}}.
{KEY}        : {token, {key, TokenLine, extract_key(TokenChars)}}.

Erlang code.

extract_string(Chars) ->
    list_to_binary(lists:sublist(Chars, 2, length(Chars) - 2)).

extract_key(Chars) ->
      list_to_binary(Chars).
