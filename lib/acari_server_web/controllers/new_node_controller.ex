defmodule AcariServerWeb.NewNodeController do
  use AcariServerWeb, :controller
  alias AcariServer.NewNodeDiscovery

  def index(conn, _params) do
    newnodes = NewNodeDiscovery.list_newnodes()
    render(conn, "index.html", newnodes: newnodes)
  end

  def new(conn, params) do
    {new_node, res} =
      with {:ok, env = %{id: id}} <- get_env(params),
           :ok <- new_dev?(id),
           {:ok, nn} <-
             AcariServer.NewNodeDiscovery.insert_or_update_new_node(%{
               name: id,
               ip_addr: conn.remote_ip |> :inet.ntoa() |> to_string(),
               params: env,
               source: "QR"
             }) do
        {nn, "Узел добавлен в таблицу обнаруженных:"}
      else
        {:error, %{errors: err}} -> {nil, "Ошибка БД: #{inspect(err)}"}
        {:error, message} -> {nil, message}
      end

    render(conn, "show.html", new_node: new_node, params: params, res: res)
  end

  defp get_env(%{"text" => text}) when is_binary(text) do
    ~r/([^\s=,;]+)\s*=\s*([^\s=,;]+)/
    |> Regex.scan(text)
    |> Enum.map(fn [_, k, v] -> {k, v} end)
    |> Enum.into(%{})
    |> find_id()
  end

  defp get_env(_), do: {:error, "Содержимое QR кода должно быть передано в параметре text"}

  defp find_id(parms = %{"id" => id}), do: {:ok, parms |> Map.put(:id, id)}

  defp find_id(parms = %{"dev" => dev, "sn" => sn}),
    do: {:ok, parms |> Map.put(:id, "#{dev}_#{sn}")}

  defp find_id(_), do: {:error, "Не удалось найти значение идентификатора"}

  defp new_dev?(id) do
    (AcariServer.NodeManager.get_node_by_name(id) && {:error, "Устройство уже зарегистрировано"}) ||
      :ok
  end

  def create(conn, %{"new_node" => new_node_params}) do
    case NewNodeDiscovery.create_new_node(new_node_params) do
      {:ok, new_node} ->
        conn
        |> put_flash(:info, "Новый узел успешно создан.")
        |> redirect(to: Routes.new_node_path(conn, :show, new_node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)
    render(conn, "show.html", new_node: new_node)
  end

  def edit(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)

    redirect(conn,
      to: Routes.node_path(conn, :new, name: new_node.name)
    )
  end

  def update(conn, %{"id" => id, "new_node" => new_node_params}) do
    new_node = NewNodeDiscovery.get_new_node!(id)

    case NewNodeDiscovery.update_new_node(new_node, new_node_params) do
      {:ok, new_node} ->
        conn
        |> put_flash(:info, "New node updated successfully.")
        |> redirect(to: Routes.new_node_path(conn, :show, new_node))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", new_node: new_node, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)
    {:ok, _new_node} = NewNodeDiscovery.delete_new_node(new_node)

    conn
    |> put_flash(:info, "New node deleted successfully.")
    |> redirect(to: Routes.new_node_path(conn, :index))
  end
end
