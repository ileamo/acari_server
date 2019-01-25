defmodule AcariServer.SFX do
  alias AcariServer.TemplateAgent
  @setup "setup"

  def create_sfx(templ_id, node, req_params) do
    res =
      with %{params: config_params, script: %{} = script} <- node,
           templ when is_binary(templ) <-
             AcariServer.Template.get_script_with_prefix(script, templ_id),
           prefix <- script.prefix || "",
           assigns <-
             req_params
             |> Map.merge(config_params)
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end),
           :ok <- TemplateAgent.init_templ_map(self(), assigns, prefix),
           :ok <- TemplateAgent.add_templ(self(), @setup),
           {script, nil} <- AcariServer.Template.eval(templ, assigns) do
        TemplateAgent.add_templ(self(), @setup, script)
        templ_map = TemplateAgent.get_templ_map(self())
        makeself(templ_map)
      else
        %AcariServer.NodeManager.Node{script: nil} -> create_setup("Нет шаблона для #{@setup}")
        res -> create_setup("Ошибка при создании SFX: #{inspect(res)}")
      end

    # TemplateAgent.remove_templ_map(self())
    TemplateAgent.gc()
    res
  end

  defp create_setup(text) do
    """
    #!/bin/sh
    #
    # #{text}
    #
    echo #{inspect(text)}
    """
  end

  defp makeself(templ_map) do
    case templ_map
         |> Enum.reduce([], fn
           {k, nil}, acc when is_binary(k) -> [k | acc]
           _, acc -> acc
         end) do
      [] ->
        do_makeself(templ_map)

      list ->
        create_setup("Нет шаблонов или ошибка в шаблоне для файлов #{list |> Enum.join(", ")}")
    end
  end

  def do_makeself(templ_map) do
    IO.inspect(templ_map)
    {:ok, dir_path} = Temp.mkdir("acari")

    templ_map
    |> Enum.each(fn
      {file_name, content} when is_binary(file_name) ->
        File.write(Path.join(dir_path, file_name), content |> String.replace("\r\n", "\n"))

      _ ->
        nil
    end)

    File.chmod(Path.join(dir_path, @setup), 0o755)

    {:ok, sfx_filename} = Temp.path()

    System.cmd(System.cwd() <> "/priv/usr/makeself.sh", [
      dir_path,
      sfx_filename,
      "acari",
      "./" <> @setup
    ])

    {:ok, content} = File.read(sfx_filename)
    content
  end
end
