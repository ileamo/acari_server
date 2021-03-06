defmodule AcariServer.SysConfig do
  defmacro component_common(
             component_assigns \\ Macro.escape(%{}),
             func \\ quote(do: fn x -> x end)
           ) do
    quote do
      @impl true
      def update(assigns, socket) do
        assigns =
          %{
            key: assigns.id,
            name: assigns.config.name,
            value: assigns.config.value |> unquote(func).(),
            color: "dark",
            descr: "",
            description: assigns.config.description,
            descr_pb: 0,
            select: assigns.config[:select],
            delete_list: [],
            name_error: "",
            new_value: ""
          }
          |> Map.merge(unquote(component_assigns))

        {:ok, assign(socket, assigns)}
      end

      @impl true
      def handle_event("descr", _params, socket) do
        {descr, pb} =
          if socket.assigns.descr == "", do: {socket.assigns.description, 3}, else: {"", 0}

        {:noreply, assign(socket, descr: descr, descr_pb: pb)}
      end

      def handle_event("descr_off", _params, socket) do
        {:noreply, assign(socket, descr: "", descr_pb: 0)}
      end
    end
  end
end
