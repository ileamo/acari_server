defmodule AcariServer.AuditManager do
  @moduledoc """
  The AuditManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo

  alias AcariServer.AuditManager.Audit

  @doc """
  Returns the list of audit_logs.

  ## Examples

      iex> list_audit_logs()
      [%Audit{}, ...]

  """
  def list_audit_logs do
    Repo.all(Audit)
  end

  @doc """
  Gets a single audit.

  Raises `Ecto.NoResultsError` if the Audit does not exist.

  ## Examples

      iex> get_audit!(123)
      %Audit{}

      iex> get_audit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_audit!(id), do: Repo.get!(Audit, id)

  @doc """
  Creates a audit.

  ## Examples

      iex> create_audit(%{field: value})
      {:ok, %Audit{}}

      iex> create_audit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_audit(attrs \\ %{}) do
    %Audit{}
    |> Audit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a audit.

  ## Examples

      iex> delete_audit(audit)
      {:ok, %Audit{}}

      iex> delete_audit(audit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_audit(%Audit{} = audit) do
    Repo.delete(audit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking audit changes.

  ## Examples

      iex> change_audit(audit)
      %Ecto.Changeset{source: %Audit{}}

  """
  def change_audit(%Audit{} = audit) do
    Audit.changeset(audit, %{})
  end
end
