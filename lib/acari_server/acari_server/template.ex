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

  def test_assigns(nil), do: {nil, nil}

  def test_assigns(json) do
    # with json <- String.trim(json),
    #     json <- (String.match?(json, ~r/^{.*}$/) && json) || "{" <> json <> "}",
    with {:ok, %{"test" => test_ass} = dfns} <- Jason.decode(json) do
      (dfns["var"] || %{})
      |> Map.merge(dfns["const"] || %{})
      |> Map.merge(test_ass)
      |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
      |> Enum.into(%{})
      |> (fn m -> {m, nil} end).()
    else
      # if decode :ok but no test key
      {:ok, _} -> {nil, nil}
      {:error, mes} -> {nil, mes}
      res -> {nil, inspect(res)}
    end
  end

  def highlight_char(text, n) do
    n = min(n, byte_size(text) - 1)
    <<head::binary-size(n), tail::binary>> = text
    {char, tail} = String.split_at(tail, 1)
    {head, char, tail}
  end
end
