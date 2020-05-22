defmodule AcariServer.SysConfigManager.Schema do
  def get do
    [
      %{
        key: "layout.navbar.banner",
        name: "Баннер",
        description: "Задает текст в верхней навигационной панели",
        type: :string
      },
      %{
        key: "admin.ro_plus",
        name: "Просмотр+",
        description:
          "Разрешить пользователю с ограниченными правами редактировать информационные параметры клиента",
        type: :boolean
      }
    ]
    |> Enum.uniq_by(fn %{key: key} -> key end)
  end
end
