defmodule Acari.Const do
  @tun_mask 2
  @link_mask 3

  defmacro tun_mask, do: @tun_mask
  defmacro link_mask, do: @link_mask

  defmacro tun_com(com) do
    quote do
      <<unquote(@tun_mask)::2, unquote(com)::14>>
    end
  end

  defmacro link_com(com) do
    quote do
      <<unquote(@link_mask)::2, unquote(com)::14>>
    end
  end

  # Link messages
  defmacro echo_reply, do: 0
  defmacro echo_request, do: 1

  # tun messages
  defmacro master_mes, do: 0
  defmacro json_req, do: 1
  defmacro peer_started, do: 2
  defmacro master_mes_plus, do: 3
end
