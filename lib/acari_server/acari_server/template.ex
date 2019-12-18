defmodule AcariServer.Template do
  defp std_funcs() do
    %{
      "path_to" => fn x, _render ->
        TemplFunc.path_to(x |> String.trim())
      end,
      "include_file" => fn x, _render ->
        TemplFunc.include_file(x |> String.trim())

      end
    }
  end

  def eval(templ, assigns \\ %{}) do
    templ = templ || ""

    assigns =
      assigns
      |> Enum.map(fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        other -> other
      end)
      |> Enum.into(%{})

    try do
      embed =
        :bbmustache.render(
          templ,
          assigns
          |> Map.put("fn", std_funcs()),
          key_type: :binary,
          escape_fun: & &1
        )

      {:ok, embed}
    rescue
      e in ErlangError ->
        case e do
          %ErlangError{original: {err_type, {mes, line}}} ->
            {:error, "#{err_type}: #{mes}: #{inspect(line)}"}

          _ ->
            {:error, inspect(e)}
        end

      x ->
        stack =
          case __STACKTRACE__ do
            [{:erlang, func, args, _} | _] -> ": #{func}(#{Enum.join(args, ", ")})"
            _ -> ""
          end

        {:error, "#{Exception.message(x)}#{stack}"}
    end
  end

  def eval_EEX(templ, assigns \\ %{}) do
    templ = templ || ""

    try do
      {EEx.eval_string(templ, assigns: assigns), nil}
    rescue
      x ->
        stack =
          case __STACKTRACE__ do
            [{:erlang, func, args, _} | _] -> ": #{func}(#{Enum.join(args, ", ")})"
            _ -> ""
          end

        {nil, "#{Exception.message(x)}#{stack}"}
    end
  end

  def test_assigns(var, tst) when not (is_map(var) and is_map(tst)), do: nil

  def test_assigns(var, tst) do
    var
    |> Map.merge(tst)
    |> get_only_value()
    |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
    |> Enum.into(%{})
  end

  def highlight_char(text, n) do
    n = min(n, byte_size(text) - 1)
    <<head::binary-size(n), tail::binary>> = text
    {char, tail} = String.split_at(tail, 1)
    {head, char, tail}
  end

  def highlight_line(text, n) when n > 0 do
    case Regex.scan(~r/[^\n]*\n/, text, return: :index) |> Enum.at(n - 1) do
      [{start, len}] ->
        {text |> binary_part(0, start), text |> binary_part(start, len),
         text
         |> binary_part(start + len, byte_size(text) - (start + len))}

      _ ->
        {text, "", ""}
    end
  end

  def highlight_line(text, _) do
    {text, "", ""}
  end

  def get_line(str) do
    case Regex.run(~r|(\d+):|, str) do
      [_, n] -> n |> String.to_integer()
      _ -> 0
    end
  end

  def get_json(nil), do: {%{}, nil}

  def get_json(json) do
    case Jason.decode(json) do
      {:ok, %{} = var} -> {var, nil}
      {:error, err} -> {nil, err}
    end
  end

  def get_vars(nil), do: %{}

  def get_vars(json) do
    case Jason.decode(json) do
      {:ok, %{} = var} -> normalize_vars(var)
      _ -> %{}
    end
  end

  def get_script_with_prefix(script, templ) do
    case Map.get(script, templ) do
      scr when is_binary(scr) -> (script.prefix || "") <> scr
      _ -> ""
    end
  end

  defp normalize_vars(var) do
    var
    |> Enum.map(&check_var/1)
    |> Enum.reject(fn x -> x == nil end)
    |> Enum.into(%{})
  end

  defp check_var({k, v})
       when is_binary(k) and (is_binary(v) or is_number(v) or is_boolean(v)) do
    {k, to_string(v)}
  end

  defp check_var({k, v}) when is_binary(k) and is_list(v) do
    case Enum.all?(v, fn x -> is_binary(x) || is_number(x) || is_boolean(x) end) do
      true -> {k, v |> Enum.map(&Kernel.to_string/1)}
      _ -> nil
    end
  end

  defp check_var(_), do: nil

  def get_only_value(var) do
    var
    |> normalize_vars()
    |> Enum.map(fn
      {k, [v | _]} -> {k, v}
      {k, v} -> {k, v}
    end)
    |> Enum.into(%{})
  end

  def humanize_lua_err(err) do
    case err do
      {:badmatch, {:error, [{_line, :luerl_parse, list}], []}} when is_list(list) ->
        Enum.join(list)

      {:badmatch, {:error, [{_line, :luerl_scan, {a, s}}], []}} when is_atom(a) ->
        "#{a} #{inspect(s)}"

      {:lua_error, {t, a, b}, _} when is_atom(t) ->
        "#{t} #{inspect(a)} #{inspect(b)}"

      {:lua_error, {t, a}, _} when is_atom(t) ->
        "#{t} #{inspect(a)}"

      err ->
        inspect(err)
    end
  end

  def eval_prefix(script, test_ass) do
    case Sandbox.init()
         |> Sandbox.set!("params", test_ass)
         |> Sandbox.eval(script) do
      {:ok, res} ->
        if res
           |> Enum.all?(fn
             {k, _v} when is_binary(k) -> true
             _ -> false
           end) do
          {:ok, res |> Enum.into(%{})}
        else
          {:error, "Результатом вычисления должна быть таблица пар ключ-значение"}
        end

      {:error, err} ->
        {:error, humanize_lua_err(err)}
    end
  end
end
