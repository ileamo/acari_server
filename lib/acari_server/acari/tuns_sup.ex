defmodule Acari.TunsSup do
  use DynamicSupervisor

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Client
  def start_tun(tun_name, master_pid \\ nil, peer_params \\ %{})

  def start_tun(tun_name, master_pid, peer_params) when is_binary(tun_name) do

    case DynamicSupervisor.start_child(
           __MODULE__,
           {Acari.TunSup, %{tun_name: tun_name, master_pid: master_pid, peer_params: peer_params}}
         ) do
      {:ok, _pid} -> :ok
      error -> error
    end
  end

  def start_tun(_, _, _), do: {:error, "Tunnel name must be string"}

  def stop_tun(tun_name) do
    case Registry.lookup(Registry.TunSup, tun_name) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(Acari.TunsSup, pid)
      _ -> {:error, "No tunnel '#{tun_name}'"}
    end
  end

  def tun_exist?(tun_name) do
    case Registry.lookup(Registry.TunSup, tun_name) do
      [{_, _}] -> true
      _ -> false
    end
  end
end
