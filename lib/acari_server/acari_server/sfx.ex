defmodule AcariServer.SFX do
  alias AcariServer.TemplateAgent
  alias AcariServer.NodeManager
  alias AcariServer.ScriptManager.Script

  def create_script_from_template(node_name, templ_id, params \\ %{}) do
    case NodeManager.get_node_with_class(node_name) do
      %NodeManager.Node{script: %Script{} = class} = node ->
        templ_id =
          case templ_id do
            templ_id when is_binary(templ_id) ->
              templ_id

            :local ->
              (class = AcariServer.RepoRO.preload(class, :local)) && class.local &&
                class.local.name

            :remote ->
              (class = AcariServer.RepoRO.preload(class, :remote)) && class.remote &&
                class.remote.name

            _ ->
              nil
          end

        {create_sfx(templ_id, node, Map.put(params, "id", node_name)), templ_id}

      _ ->
        {create_setup("Нет клиента #{node_name} или ему не назначен класс"), nil}
    end
  end

  def create_sfx(templ_id, node, req_params) do
    res =
      with main_templ_name when is_binary(main_templ_name) <- templ_id,
           %{script: %{} = class} <- node,
           prefix <- class.prefix || "",
           assigns <- AcariServer.Template.get_assignments(node, params: req_params),
           :ok <- TemplateAgent.init_templ_map(self(), assigns, prefix),
           setup_file_name <- TemplFunc.path_to(main_templ_name) do
        templ_map = TemplateAgent.get_templ_map(self())
        makeself(templ_map, setup_file_name)
      else
        %NodeManager.Node{script: nil, name: name} ->
          create_setup("Клиенту #{name} не назначен класс")

        res ->
          create_setup("Ошибка при создании SFX: #{inspect(res)}")
      end

    TemplateAgent.remove_templ_map(self())
    TemplateAgent.gc()
    res
  end

  def create_setup(text) do
    """
    #!/bin/sh
    #ERROR
    #
    # #{text}
    #
    echo #{inspect(text)}
    """
  end

  defp makeself(templ_map, setup_file_name) do
    case templ_map
         |> Enum.reduce([], fn
           {k, nil}, acc when is_binary(k) -> [k | acc]
           _, acc -> acc
         end) do
      [] ->
        do_makeself_or_script(templ_map, setup_file_name)

      list ->
        create_setup("Нет шаблонов или ошибка в шаблоне для файлов #{list |> Enum.join(", ")}")
    end
  end

  def do_makeself_or_script(templ_map, setup_file_name) do
    case templ_map
         |> Enum.reduce_while(nil, fn
           {name, content}, acc when is_binary(name) and is_binary(content) and is_nil(acc) ->
             {:cont, content}

           {name, content}, acc when is_binary(name) and is_binary(content) and is_binary(acc) ->
             {:halt, :many}

           _, acc ->
             {:cont, acc}
         end) do
      nil -> create_setup("Нет шаблонов для создания скрипта")
      :many -> do_makeself(templ_map, setup_file_name)
      content -> content |> String.replace("\r\n", "\n")
    end
  end

  def do_makeself(templ_map, setup_file_name) do
    with {:ok, dir_path} <- Temp.mkdir("acari"),
         :ok <-
           templ_map
           |> Enum.each(fn
             {file_name, content} when is_binary(file_name) ->
               File.write(Path.join(dir_path, file_name), content |> String.replace("\r\n", "\n"))

             _ ->
               nil
           end),
         :ok <- File.chmod(Path.join(dir_path, setup_file_name), 0o755),
         {:ok, sfx_filename} <- Temp.path(),
         {:ok, cwd} <- File.cwd(),
         makeself_sh = cwd <> "/priv/usr/makeself.sh",
         :ok <-
           if(File.exists?(makeself_sh), do: :ok, else: {:error, "No such file #{makeself_sh}"}),
         {_, 0} <-
           System.cmd(
             makeself_sh,
             [
               "--nomd5",
               "--nocrc",
               dir_path,
               sfx_filename,
               "acari",
               setup_file_name
             ],
             stderr_to_stdout: true
           ),
         {:ok, content} <- File.read(sfx_filename) do
      content
    else
      res -> create_setup("Ошибка при создании SFX: #{inspect(res)}")
    end
  end
end
