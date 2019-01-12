defmodule AcariServer.Template do
  def eval(templ, assigns \\ %{}) do
    try do
      EEx.eval_string(templ, assigns: assigns)
    rescue
      x ->
        stack =
          case __STACKTRACE__ do
            [{:erlang, func, args, _} | _] -> ": #{func}(#{Enum.join(args, ", ")})"
            _ -> ""
          end

        {:error, "#{Exception.message(x)}#{stack}"}
    end
  end

  def test_assigns(json) do
    with {:ok, %{"test" => test_ass} = dfns} <- Jason.decode(json) do
      (dfns["var"] || %{})
      |> Map.merge(dfns["const"] || %{})
      |> Map.merge(test_ass)
      |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
      |> Enum.into(%{})
    else
      _ -> nil
    end
  end
end
