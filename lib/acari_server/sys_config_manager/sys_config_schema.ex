defmodule AcariServer.SysConfigManager.Schema do
  def get do
    [
      %{
        key: "layout.navbar.banner",
        name: "Баннер",
        description: "Техт в верхней навигационной панели",
        type: :string
      },
      %{
        key: "layout.color",
        name: "Цвет",
        description: "Цвет",
        type: :string
      }
    ]
    |> Enum.uniq_by(fn %{key: key} -> key end)
  end

end
