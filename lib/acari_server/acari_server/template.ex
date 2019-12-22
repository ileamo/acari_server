defmodule AcariServer.Template do
  alias AcariServer.NodeManager
  alias AcariServer.NodeManager.Node

  def eval_template(template, test_params) do
    case NodeManager.get_node_with_class(String.trim(template.test_client_name || "")) do
      %Node{script: %AcariServer.ScriptManager.Script{} = class} = client ->
        base_assigns = AcariServer.Template.get_assignments(client, test_params)

        AcariServer.Template.eval(template, class.prefix, base_assigns)

      nil ->
        {:error, :no_client}

      %{script: nil} ->
        {:error, :no_class}

      res ->
        {:error, inspect(res)}
    end
  end

  def eval(template, prefix, assigns \\ %{}) do
    templ =
      case template do
        %{template: templ} -> templ
        _ -> ""
      end

    assigns =
      assigns
      |> Map.put("template", %{
        "name" => template.name,
        "description" => template.description,
        "rights" => template.rights,
        "executable" => template.executable
      })

    with {:ok, calculated} <-
           eval_class_assigns(prefix, assigns) do
      try do
        embed =
          :bbmustache.render(
            templ,
            assigns
            |> Map.merge(calculated)
            |> Map.put("fn", TemplFunc.std_funcs()),
            key_type: :binary,
            escape_fun: & &1
          )

        {:ok, embed}
      rescue
        e in ErlangError ->
          case e do
            %ErlangError{original: {err_type, {mes, line}}} ->
              {:error, "#{err_type}: #{mes}: #{inspect(line)}"}

            %ErlangError{original: {err_type, mes}} ->
              {:error, "#{err_type}: #{mes}"}

            _ ->
              {:error, inspect(e)}
          end

        x ->
          stack =
            case __STACKTRACE__ do
              [{:erlang, func, args, _} | _] -> ": #{func}(#{Enum.join(args, ", ")})"
              _ -> ""
            end

          {:error, "#{Exception.message(x)}#{stack}"}
      end
    else
      {:error, mes} -> {:error, "Ошибка вычисления параметров: #{mes}"}
      res -> res
    end
  end

  def test_assigns(var, tst) when not (is_map(var) and is_map(tst)), do: nil

  def test_assigns(var, tst) do
    var
    |> Map.merge(tst)
    |> get_only_value()
    |> Enum.into(%{})
  end

  def get_only_value(var) do
    var
    |> normalize_vars()
    |> Enum.map(fn
      {k, [v | _]} -> {k, v}
      {k, v} -> {k, v}
    end)
    |> Enum.into(%{})
  end

  def highlight_char(text, n) do
    n = min(n, byte_size(text) - 1)
    <<head::binary-size(n), tail::binary>> = text
    {char, tail} = String.split_at(tail, 1)
    {head, char, tail}
  end

  def highlight_line(text, n) when n > 0 do
    case Regex.scan(~r/[^\n]*\n/, text, return: :index) |> Enum.at(n - 1) do
      [{start, len}] ->
        {text |> binary_part(0, start), text |> binary_part(start, len),
         text
         |> binary_part(start + len, byte_size(text) - (start + len))}

      _ ->
        {text, "", ""}
    end
  end

  def highlight_line(text, _) do
    {text, "", ""}
  end

  def get_line(str) do
    case Regex.run(~r|(\d+):|, str) do
      [_, n] -> n |> String.to_integer()
      _ -> 0
    end
  end

  def get_json(nil), do: {%{}, nil}

  def get_json(json) do
    case Jason.decode(json) do
      {:ok, %{} = var} -> {var, nil}
      {:error, err} -> {nil, err}
    end
  end

  def get_vars(nil), do: %{}

  def get_vars(json) do
    case Jason.decode(json) do
      {:ok, %{} = var} -> normalize_vars(var)
      _ -> %{}
    end
  end

  def get_script_with_prefix(script, templ) do
    case Map.get(script, templ) do
      scr when is_binary(scr) -> (script.prefix || "") <> scr
      _ -> ""
    end
  end

  defp normalize_vars(var) do
    var
    |> Enum.map(&check_var/1)
    |> Enum.reject(fn x -> x == nil end)
    |> Enum.into(%{})
  end

  defp check_var({k, v})
       when is_binary(k) and (is_binary(v) or is_number(v) or is_boolean(v)) do
    {k, to_string(v)}
  end

  defp check_var({k, v}) when is_binary(k) and is_list(v) do
    case Enum.all?(v, fn x -> is_binary(x) || is_number(x) || is_boolean(x) end) do
      true -> {k, v |> Enum.map(&Kernel.to_string/1)}
      _ -> nil
    end
  end

  defp check_var(_), do: nil

  def humanize_lua_err(err) do
    case err do
      {:badmatch, {:error, [{_line, :luerl_parse, list}], []}} when is_list(list) ->
        Enum.join(list)

      {:badmatch, {:error, [{_line, :luerl_scan, {a, s}}], []}} when is_atom(a) ->
        "#{a} #{inspect(s)}"

      {:lua_error, {t, a, b}, _} when is_atom(t) ->
        "#{t} #{inspect(a)} #{inspect(b)}"

      {:lua_error, {t, a}, _} when is_atom(t) ->
        "#{t} #{inspect(a)}"

      err ->
        inspect(err)
    end
  end

  def eval_class_assigns(script, assigns \\ %{})

  def eval_class_assigns(nil, _) do
    {:ok, %{}}
  end

  def eval_class_assigns(script, assigns) do
    if String.trim(script) == "" do
      {:ok, %{}}
    else
      with {:ok, res} when is_list(res) <-
             Sandbox.init()
             |> set_each(assigns)
             |> Sandbox.eval(script),
           true <-
             Enum.all?(res, fn
               {k, v}
               when is_binary(k) and
                      (is_binary(v) or is_boolean(v) or is_integer(v) or is_float(v)) ->
                 true

               _ ->
                 false
             end) do
        {:ok, res |> Enum.into(%{})}
      else
        false -> {:error, "Значением ключа должна быть строка, число, true или false"}
        {:ok, _} ->
          {:error, "Результатом вычисления должна быть таблица пар ключ-значение"}

        {:error, err} ->
          {:error, humanize_lua_err(err)}
      end
    end
  end

  defp set_each(lua_state, assigns) do
    assigns
    |> Enum.reduce(lua_state, fn {var, value}, lua_state ->
      Sandbox.set!(lua_state, var, value)
    end)
  end

  def get_assignments(%Node{} = client, params) do
    class = client.script

    %{
      "id" => client.name,
      "class" => %{
        "name" => class.name,
        "description" => class.description
      },
      "client" => %{
        "name" => client.name,
        "description" => client.description,
        "latitude" => client.latitude,
        "longitude" => client.longitude,
        "lock" => client.lock,
        "params" => client.params || %{}
      },
      "params" =>
        AcariServer.Master.get_tun_params(client.name)
        |> Map.merge(params)
    }
  end

  def get_assignments(%AcariServer.ScriptManager.Script{id: class_id} = class) do
    client_name = String.trim(class.test_client_name || "")

    with %Node{script: %{id: ^class_id}} = client <-
           NodeManager.get_node_with_class(client_name) do
      get_assignments(client, %{})
    else
      _ ->
        client_name =
          case client_name do
            "" -> "DEVICE_2001001234"
            n -> n
          end

        params =
          case Jason.decode(class.definition || "") do
            {:ok, params_definition} -> get_only_value(params_definition)
            _ -> %{}
          end

        %{
          "id" => client_name,
          "class" => %{
            "name" => class.name,
            "description" => class.description
          },
          "client" => %{
            "name" => client_name,
            "description" => "CLIENT_DESCRIPTION",
            "latitude" => "0.0",
            "longitude" => "0.0",
            "lock" => false,
            "params" => params
          }
        }
    end
    |> Map.put("template", %{
      "name" => "TEMPLATE_NAME",
      "description" => "TEMPLATE_DESCRIPTION",
      "rights" => "TEMPLATE_RIGHTS",
      "executable" => true
    })
  end

  def get_assignments(_), do: %{}
end
