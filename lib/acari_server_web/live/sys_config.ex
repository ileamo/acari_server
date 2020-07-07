defmodule AcariServer.SysConfig do
  defmacro component_common do
    quote do
      @impl true
      def update(assigns, socket) do
        {:ok,
         assign(socket,
           key: assigns.id,
           name: assigns.config.name,
           value: assigns.config.value,
           color: "dark",
           descr: "",
           description: assigns.config.description,
           descr_pb: 0,
           select: assigns.config[:select],
           show_map: false
         )}
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
