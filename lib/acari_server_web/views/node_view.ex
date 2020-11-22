defmodule AcariServerWeb.NodeView do
  use AcariServerWeb, :view
  @no_script "<NO_CLASS>"

  def script_name(node) do
    case node.script do
      nil -> @no_script
      scr -> scr.name
    end
  end

  defdelegate group_name_id_pairs_list(), to: AcariServer.GroupManager

  def script_name_id_pairs_list() do
    AcariServer.ScriptManager.script_name_id_pairs_list(@no_script)
  end

  def param_list(nil), do: ""

  def param_list(param_map) do
    param_map
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join(", ")
  end

  def links_to_groups_list(conn, groups) do
    case groups do
      [_ | _] ->
        groups
        |> Enum.map(fn group ->
          link(group.name, to: Routes.node_path(conn, :client_grp, group), class: "mr-3")
        end)

      _ ->
        link("К списку клиентов", to: Routes.node_path(conn, :index))
    end
  end

  def lock_state(node) do
    if node.lock do
      {"text-muted", "off", "Разблокировать клиента?"}
    else
      {"", "on", "Заблокировать клиента?"}
    end
  end

  def multi_col(vars) do
    gr =
      vars
      |> Enum.group_by(fn {name, _} ->
        case Regex.run(~r|^[^_]+_(.+)$|, name) do
          [_, name] -> name
          _ -> "_" <> name
        end
      end)
      |> Enum.sort_by(fn {_name, list = [{name1, _} | _]} -> {-length(list), name1} end)

    max =
      gr
      |> Enum.max_by(fn {_, list} -> length(list) end)
      |> elem(1)
      |> length()

    cols =
      case max do
        1 -> 1
        2 -> 2
        3 -> 3
        4 -> 4
        5 -> 3
        6 -> 3
        _ -> 4
      end

    rows =
      gr
      |> Enum.map(fn {_, x} ->
        x
        |> Enum.chunk_every(cols, cols, List.duplicate(nil, cols - 1))
      end)
      |> List.flatten()
      |> Enum.chunk_every(cols, cols, List.duplicate(nil, cols - 1))

    {cols, rows}
  end
end
