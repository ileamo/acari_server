defmodule AcariServer.SysConfigManager.Schema do
  def get do
    [
      # %{
      #   key: "layout.navbar.theme",
      #   name: "Тема",
      #   description: "Цветовая схема верхней навигационной панели",
      #   type: :select,
      #   select: [
      #     {"default", "Умолчательная"},
      #     {"dark", "Темная"},
      #     {"light", "Светлая"},
      #   ]
      # },
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
      },
      %{
        key: "system.url.mobile",
        name: "URL",
        description: "URL для доступа к серверу Богатка с мобильных устройств",
        type: :string
        }
    ]
    |> Enum.uniq_by(fn %{key: key} -> key end)
  end
end
