defmodule AcariServer.SysConfigManager.SysConfig do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sysconfigs" do
    field :name, :string
    field :value, :string

    timestamps()
  end

  @doc false
  def changeset(sys_config, attrs) do
    sys_config
    |> cast(attrs, [:name, :value])
    |> validate_required([:name, :value])
  end
end
