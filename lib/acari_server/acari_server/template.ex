defmodule AcariServer.Template do
  def eval(templ, assigns \\ %{}) do
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
    {k, v}
  end

  defp check_var({k, v}) when is_binary(k) and is_list(v) do
    case Enum.all?(v, fn x -> is_binary(x) || is_number(x) || is_boolean(x) end) do
      true -> {k, v}
      _ -> nil
    end
  end

  defp check_var(_), do: nil

  defp get_only_value(var) do
    var
    |> normalize_vars()
    |> Enum.map(fn
      {k, [v | _]} -> {k, v}
      {k, v} -> {k, v}
    end)
    |> Enum.into(%{})
  end
end
