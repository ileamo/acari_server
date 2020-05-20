defmodule AcariServer.SysConfigManager.SysConfig do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sysconfigs" do
    field :key, :string
    field :value, :string

    timestamps()
  end

  @doc false
  def changeset(sys_config, attrs) do
    sys_config
    |> cast(attrs, [:key, :value])
    |> validate_required([:key])
  end
end
