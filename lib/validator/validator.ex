defmodule AcariServer.Validator do
  def validators() do
    %{
      "nsgconfig" => &AcariServer.Validator.NSGconfParser.parse/1,
      "elixir" => &exs_validator/1,
      "<NO_VALIDATOR>" => fn _ -> :ok end
    }
  end

  def get_validator_list() do
    validators() |> Enum.map(fn {name, _} -> name end)
    |> Enum.sort()
  end

  defp exs_validator(text) do
    case Code.string_to_quoted(text) do
      {:ok, _} -> :ok
      {:error, {line, error, _token}} -> "#{line}: #{error}"
    end
  end
end
