defmodule AcariServerWeb.NewNodeController do
  use AcariServerWeb, :controller
  alias AcariServer.NewNodeDiscovery
  alias AcariServer.NodeManager

  import AcariServer.UserManager, only: [is_admin: 2]
  plug :is_admin when action in [:edit, :delete, :new, :upload]

  def index(conn, params) do
    newnodes = NewNodeDiscovery.list_newnodes()
    render(conn, "index.html", newnodes: newnodes, err_mes: params["err_mes"])
  end

  def new(conn, params) do
    {new_node, res} =
      with {:ok, env = %{"id" => id}} <- get_env(params),
           :ok <- new_dev?(id),
           {:ok, nn} <-
             AcariServer.NewNodeDiscovery.insert_or_update_new_node(%{
               name: id,
               ip_addr: conn.remote_ip |> :inet.ntoa() |> to_string(),
               params: env,
               source: "QR"
             }) do
        {nn, "Клиент добавлен в таблицу обнаруженных:"}
      else
        {:error, %{errors: err}} -> {nil, "Ошибка БД: #{inspect(err)}"}
        {:error, message} -> {nil, message}
      end

    conn
    |> put_layout("qr_layout.html")
    |> render("show.html", new_node: new_node, params: params, res: res)
  end

  defp get_env(%{"text" => text}) when is_binary(text) do
    ~r/([^\s=,;]+)\s*=\s*([^\s=,;]+)/
    |> Regex.scan(text)
    |> Enum.map(fn [_, k, v] -> {k, v} end)
    |> Enum.into(%{})
    |> find_id()
  end

  defp get_env(_), do: {:error, "Содержимое QR кода должно быть передано в параметре text"}

  defp find_id(parms = %{"id" => id}), do: {:ok, parms |> Map.put("id", id)}

  defp find_id(parms = %{"dev" => dev, "sn" => sn}),
    do: {:ok, parms |> Map.put("id", "#{dev}_#{sn}")}

  defp find_id(_), do: {:error, "Не удалось найти значение идентификатора"}

  defp new_dev?(id) do
    (NodeManager.get_node_by_name(id) &&
       {:error, "Клиент уже зарегистрирован"}) ||
      :ok
  end

  def create(conn, %{"new_node" => new_node_params}) do
    case NewNodeDiscovery.create_new_node(new_node_params) do
      {:ok, new_node} ->
        conn
        |> put_flash(:info, "Новый клиент успешно создан.")
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
      to: Routes.node_path(conn, :new, new_node.params)
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

  def unlock(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)
    node = NodeManager.get_node_by_name(new_node.name)
    node_params = %{"lock" => false, "groups_list" => false}
    NodeManager.update_node(node, node_params)

    conn
    |> redirect(to: Routes.new_node_path(conn, :index))
  end

  def delete(conn, %{"id" => id}) do
    new_node = NewNodeDiscovery.get_new_node!(id)
    {:ok, _new_node} = NewNodeDiscovery.delete_new_node(new_node)

    conn
    |> put_flash(:info, "New node deleted successfully.")
    |> redirect(to: Routes.new_node_path(conn, :index))
  end

  def upload(conn, params) do
    err_mes =
      cond do
        upload = params["upload"] ->
          case File.read(upload.path) do
            {:ok, text} ->
              case add_new_client(text, params) do
                {:error, mes} -> mes
                _ -> ""
              end

            _ ->
              "Не могу загрузить файл #{upload.filename}"
          end

        text = params["text"] ->
          case add_new_client(text, params) do
            {:error, mes} -> mes
            _ -> ""
          end
      end

    case err_mes do
      "" -> put_flash(conn, :info, "Клиенты зарегистрированы")
      _ -> put_flash(conn, :error, "Ошибки при регистрации клиентов")
    end
    |> redirect(to: Routes.new_node_path(conn, :index, err_mes: err_mes))
  end

  defp add_new_client(text, client_params) do
    case String.printable?(text) do
      true -> add_new_client_(text, client_params)
      _ -> {:error, "Файл содержит непечатные символы"}
    end
  end

  defp add_new_client_(text, client_params) do
    var_def =
      with class when is_binary(class) <- client_params["script_id"],
           {class_id, ""} <- Integer.parse(class),
           %{definition: def} <- AcariServer.ScriptManager.get_script(class_id) do
        AcariServer.Template.get_vars(def)
      else
        _ ->
          nil
      end

    case AcariServer.Parser.client_list(text) do
      {:ok, res, _, _, _, _} ->
        res
        |> Enum.map(fn kv_list ->
          case kv_list
               |> Enum.map(fn [k, v] ->
                 {to_string(k), to_string(v)}
               end)
               |> Enum.into(%{})
               |> find_id() do
            {:ok, params} ->
              with env = %{"id" => id} <- params,
                   :ok <- new_dev?(id),
                   {:ok, _} <-
                     NodeManager.create_node(
                       env
                       |> Map.merge(client_params)
                       |> Map.merge(%{"name" => id, "lock" => true}),
                       var_def
                     ) do
                nil
              else
                {:error, %{errors: err}} ->
                  {:error, "#{kv_list_to_string(kv_list)}: Ошибка БД: #{inspect(err)}"}

                {:error, message} ->
                  {:error, "#{kv_list_to_string(kv_list)}: #{message}"}
              end

            {:error, mes} ->
              {:error, "#{kv_list_to_string(kv_list)}: #{mes}"}
          end
        end)
        |> Enum.reduce(nil, fn
          {:error, mes}, acc ->
            case acc do
              {:error, message} ->
                {:error, message <> "\n#{mes}"}

              nil ->
                {:error, mes}
            end

          _, acc ->
            acc
        end)

      {:error, _mes, rest, _, _, _} ->
        {:error, "Синтаксическая ошибка около\n...#{rest |> String.slice(0, 128)}"}
    end
  end

  defp kv_list_to_string(kv_list) do
    kv_list
    |> Enum.map(fn [k, v] ->
      "#{k}=#{v}"
    end)
    |> Enum.join(",")
  end
end
