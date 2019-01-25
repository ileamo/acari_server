defmodule AcariServer.TemplateAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  # API
  def init_templ_map(pid, assigns, prefix) do
    Agent.get_and_update(
      __MODULE__,
      fn state ->
        case Map.has_key?(state, pid) do
          true -> {:already_exist, state}
          _ -> {:ok, Map.put(state, pid, %{assigns: assigns, prefix: prefix})}
        end
      end
    )
  end

  def remove_templ_map(pid) do
    Agent.update(
      __MODULE__,
      fn state -> state |> Map.delete(pid) end
    )
  end

  def add_templ?(pid, templ_name) do
    Agent.get(
      __MODULE__,
      fn
        %{^pid => %{^templ_name => _}} -> false
        %{^pid => %{assigns: assigns, prefix: prefix}} -> {assigns, prefix}
        _ -> nil
      end
    )
  end

  def add_templ(pid, templ_name, templ \\ nil) do
    Agent.get_and_update(
      __MODULE__,
      fn
        %{^pid => templ_map} = state ->
          {:ok, Map.put(state, pid, templ_map |> Map.put(templ_name, templ))}

        state ->
          {:no_entry, state}
      end
    )
  end

  def get_templ_map(pid) do
    Agent.get(__MODULE__, fn state -> state[pid] end)
  end

  def get() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def gc() do
    Agent.update(
      __MODULE__,
      fn state ->
        state
        |> Enum.reject(fn {pid, _} -> not Process.alive?(pid) end)
        |> Enum.into(%{})
      end
    )
  end
end
