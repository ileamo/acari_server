defmodule AcariServer.SFX do
  alias AcariServer.TemplateAgent

  def create_sfx(templ_id, node, req_params) do
    res =
      with %{params: config_params, script: %{} = script} <- node,
           main_templ_name when is_binary(main_templ_name) <- Map.get(script, templ_id),
           prefix <- script.prefix || "",
           assigns <-
             req_params
             |> Map.merge(config_params || %{})
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end),
           :ok <- TemplateAgent.init_templ_map(self(), assigns, prefix),
           setup_file_name <- ScriptFunc.path_to(main_templ_name) do
        templ_map = TemplateAgent.get_templ_map(self())
        makeself(templ_map, setup_file_name)
      else
        res -> create_setup("Ошибка при создании SFX: #{inspect(res)}")
      end

    # TemplateAgent.remove_templ_map(self())
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
        do_makeself(templ_map, setup_file_name)

      list ->
        create_setup("Нет шаблонов или ошибка в шаблоне для файлов #{list |> Enum.join(", ")}")
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
         makeself_sh = System.cwd() <> "/priv/usr/makeself.sh",
         :ok <-
           if(File.exists?(makeself_sh), do: :ok, else: {:error, "No such file #{makeself_sh}"}),
         {_, 0} <-
           System.cmd(
             makeself_sh,
             [
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
