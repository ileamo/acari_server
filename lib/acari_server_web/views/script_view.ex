defmodule AcariServerWeb.ScriptView do
  use AcariServerWeb, :view

  defdelegate get_script_with_prefix(script, templ), to: AcariServer.Template

  def eval_prefix(script, test_ass) do
    IO.inspect(test_ass)

    case Sandbox.init()
         |> Sandbox.set!("params", test_ass)
         |> Sandbox.eval(script) do
      {:ok, res} ->
        if res
           |> Enum.all?(fn
             {k, v} when is_binary(k) -> true
             _ -> false
           end) do
          {:ok, res |> Enum.into(%{}) |> Jason.encode!(pretty: true)}
        else
          {:error, "Результатом вычисления должна быть таблица пар ключ-значение"}
        end

      {:error, err} ->
        {:error, AcariServer.Template.humanize_lua_err(err)}
    end
  end

  def eval_prefix_eex(script, test_ass) do
    AcariServer.Template.eval(script.prefix, test_ass)
  end

  def templates_list(script) do
    script.templates
    |> Enum.map(fn %{name: name} -> name end)
    |> Enum.join(", ")
  end

  def templ_id_list(nil) do
    []
  end

  def templ_id_list(script) do
    script.templates
    |> Enum.map(fn %{id: id} -> id end)
  end
end
