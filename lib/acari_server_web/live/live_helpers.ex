defmodule AcariServerWeb.LiveHelpers do
  # import Phoenix.LiveView.Helpers

  # @doc """
  # Renders a component inside the `AcariServerWeb.ModalComponent` component.

  # The rendered modal receives a `:return_to` option to properly update
  # the URL when the modal is closed.

  # ## Examples

  #     <%= live_modal @socket, AcariServerWeb.SysConfigLive.FormComponent,
  #       id: @sys_config.id || :new,
  #       action: @live_action,
  #       sys_config: @sys_config,
  #       return_to: Routes.sys_config_index_path(@socket, :index) %>
  # """
  # def live_modal(socket, component, opts) do
  #   path = Keyword.fetch!(opts, :return_to)
  #   modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
  #   live_component(socket, AcariServerWeb.ModalComponent, modal_opts)
  # end
end
