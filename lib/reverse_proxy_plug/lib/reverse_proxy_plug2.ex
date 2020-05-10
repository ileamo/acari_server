defmodule ReverseProxyPlug2 do
  defdelegate init(opts), to: ReverseProxyPlug
  defdelegate call(conn, opts), to: ReverseProxyPlug
end
