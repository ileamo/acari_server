defmodule AcariServer.Validator.NSGconfParser do
  def parse(str) do
    with {:ok, tokens, _} <- :nsgconf_lexer.string(to_charlist(str)),
         {:ok, result} <- :nsgconf_parser.parse(tokens),
         {:ok, _, _} <- check_indent(result) do
      :ok
    else
      {:error, {line, :nsgconf_lexer, {reason, rest}}, _} ->
        "#{line}: #{to_string(reason)}: #{
          Regex.run(~r/([^\n]*)\n*/, to_string(rest)) |> Enum.at(1)
        }"

      {:error, {line, :nsgconf_parser, reason}} ->
        "#{line}: #{to_string(reason)}"

      {:error, {line, :nsgconf_indent}} ->
        "#{line}: bad indent"

      other ->
        inspect(other)
    end
  end

  def check_indent(list) do
    list
    |> Enum.reduce_while({:ok, 0, 0}, fn
      {{:indent, n}, _}, {:ok, prev, line} when n - prev <= 1 ->
        {:cont, {:ok, n, line + 1}}

      {{:indent, _n}, _}, {:ok, _prev, line} ->
        {:halt, {:error, {line + 1, :nsgconf_indent}}}

      _, {:ok, prev, line} ->
        {:cont, {:ok, prev, line + 1}}
    end)
  end
end
