defmodule AcariServerWeb.GrpOperView do
  use AcariServerWeb, :view

  def get_group_scripts(nodes) do
    class_id_list =
      nodes
      |> Enum.reduce([], fn node, acc ->
        case Enum.member?(acc, node.script_id) do
          false -> [node.script_id | acc]
          _ -> acc
        end
      end)

    class_list =
      class_id_list
      |> Enum.map(fn
        nil ->
          {nil, MapSet.new()}

        id ->
          class = AcariServer.ScriptManager.get_script!(id)

          {{class.id, class.name},
           class.templates
           |> Enum.map(fn %{description: descr, name: name} -> {descr, name} end)
           |> MapSet.new()}
      end)

    common_script =
      class_list
      |> Enum.reduce(nil, fn
        {_, ms}, nil -> ms
        {_, ms}, acc -> MapSet.intersection(acc, ms)
      end)

    %{class_list: class_list, common_script: common_script}
  end
end
