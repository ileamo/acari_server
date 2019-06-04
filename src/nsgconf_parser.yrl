Terminals '=' '\n' nil indent true false key str int float whitespace.
Nonterminals config line lines cmd value ws k.
Rootsymbol config.

k ->
  key : extract_value('$1').

k ->
  str : extract_value('$1').

k ->
  int : extract_value('$1').

ws ->
  '$empty'.

ws ->
  whitespace.

config ->
  lines : '$1'.

cmd ->
  k ws : '$1'.

cmd ->
  k ws '=' ws value ws : {'$1', '$5'}.

line ->
  ws : {0}.

line ->
  cmd : {{indent, 0},'$1'}.

line ->
  indent cmd : {extract_value('$1'), '$2'}.

lines ->
  line '\n' lines : ['$1' | '$3'].

lines ->
  line : ['$1'].

value ->
  nil : nil.

value ->
  true : true.

value ->
  false : false.

value ->
  int : extract_value('$1').

value ->
  float : extract_value('$1').

value ->
  str : extract_value('$1').

Erlang code.

extract_value({_, _, Value}) ->
    Value.
