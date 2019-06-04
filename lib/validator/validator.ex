defmodule AcariServer.Validator do
  def validators() do
    %{
      "nsgconfig" => &AcariServer.Validator.NSGconfParser.parse/1,
      "<NO_VALIDATOR>" => fn _ -> :ok end
    }
  end

  def get_validator_list() do
    validators() |> Enum.map(fn {name, _} -> name end)
    |> Enum.sort()
  end
end
