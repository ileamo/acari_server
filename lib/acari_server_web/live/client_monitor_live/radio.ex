defmodule AcariServerWeb.ClientMonitorLive.Radio do
  use Phoenix.LiveComponent
  @impl true
  def update(assigns, socket) do
    port = assigns.port
    name = assigns.id


    assigns = [
      name: name,
      oper: port[:zbx]["oper[#{name}]"][:value],
      csq: get_csq(port, name),
      error: port[:errormsg][:msg],
      up: port_up(port)
    ]

    {:ok, assign(socket, assigns)}
  end

  defp get_csq(port, name) do
    case port[:zbx]["csq[#{name}]"][:value] do
      nil -> ""
      csq -> "CSQ=#{csq}"
    end
  end

  defp port_up(port) do
    (port[:links] || [])
    |> Enum.reduce_while(false, fn
      %{up: true}, _ -> {:halt, true}
      _, _ -> {:cont, false}
    end)
  end
end
