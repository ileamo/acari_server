defmodule AcariServerWeb.SysConfigLive.FormComponent do
  use AcariServerWeb, :live_component

  alias AcariServer.SysConfigManager

  @impl true
  def update(%{sys_config: sys_config} = assigns, socket) do
    changeset = SysConfigManager.change_sys_config(sys_config)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"sys_config" => sys_config_params}, socket) do
    changeset =
      socket.assigns.sys_config
      |> SysConfigManager.change_sys_config(sys_config_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"sys_config" => sys_config_params}, socket) do
    save_sys_config(socket, socket.assigns.action, sys_config_params)
  end

  defp save_sys_config(socket, :edit, sys_config_params) do
    case SysConfigManager.update_sys_config(socket.assigns.sys_config, sys_config_params) do
      {:ok, _sys_config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sys config updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_sys_config(socket, :new, sys_config_params) do
    case SysConfigManager.create_sys_config(sys_config_params) do
      {:ok, _sys_config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sys config created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
