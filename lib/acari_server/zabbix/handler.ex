defmodule AcariServer.Zabbix.Handler do
  use GenServer

  defmodule State do
    defstruct errormsg: %{}
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    {:ok, %State{}}
  end

  @impl true
  def handle_cast({:handle, host, "errormsg." <> port, value}, state) do

    AcariServer.Mnesia.update_tun_state(host, :errormsg, %{port => value})

    errormsg = state.errormsg |> put_in([Access.key(host, %{}), Access.key(port, %{})], value)
    {:noreply, %{state | errormsg: errormsg}}
  end

  def handle_cast({:handle, host, key, value}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_errormsg, host}, _from, state) do
    res =
      case host do
        nil -> state.errormsg
        _ -> state.errormsg[host]
      end

    {:reply, res, state}
  end

  def handle(host, key, value) do
    GenServer.cast(__MODULE__, {:handle, host, key, value})
  end

  def get_errormsg(host \\ nil) do
    GenServer.call(__MODULE__, {:get_errormsg, host})
  end
end
