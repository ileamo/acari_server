defmodule AcariServer.TemplateEventManager do
  @moduledoc """
  The TemplateEventManager context.
  """

  import Ecto.Query, warn: false
  alias AcariServer.Repo
  alias AcariServer.RepoRO

  alias AcariServer.TemplateEventManager.TemplateEvent

  @doc """
  Returns the list of template_events.

  ## Examples

      iex> list_template_events()
      [%TemplateEvent{}, ...]

  """
  def list_template_events do
    Repo.all(TemplateEvent)
  end

  @doc """
  Gets a single template_event.

  Raises `Ecto.NoResultsError` if the Template event does not exist.

  ## Examples

      iex> get_template_event!(123)
      %TemplateEvent{}

      iex> get_template_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template_event!(id), do: Repo.get!(TemplateEvent, id)

  def get_template_event_by_name(name) do
    from(te in TemplateEvent,
      where: te.template_name == ^name,
      order_by: te.inserted_at
    )
    |> RepoRO.all()
  end

  def get_template_events_diff(name) do
    [%{description: nil, template: nil} | get_template_event_by_name(name)]
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, next] ->
      diff =
        List.myers_difference(
          prev.template && String.split(prev.template, "\n") || [],
          String.split(next.template, "\n")
        )

      diff_count =
        diff
        |> Enum.reduce([0, 0, 0], fn
          {:ins, list}, [ins, del, diff] -> [ins + length(list), del, diff]
          {:del, list}, [ins, del, diff] -> [ins, del + length(list), diff]
          {:diff, _}, [ins, del, diff] -> [ins, del, diff + 1]
          _, acc -> acc
        end)

      diff_count = Enum.zip([:ins, :del, :diff], diff_count)

      %{
        date: next.inserted_at,
        username: next.username,
        diff: diff,
        diff_count: diff_count,
        template: next.template,
      }
    end)
    |> Enum.reverse()
  end

  @doc """
  Creates a template_event.

  ## Examples

      iex> create_template_event(%{field: value})
      {:ok, %TemplateEvent{}}

      iex> create_template_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template_event(attrs \\ %{}) do
    %TemplateEvent{}
    |> TemplateEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template_event.

  ## Examples

      iex> update_template_event(template_event, %{field: new_value})
      {:ok, %TemplateEvent{}}

      iex> update_template_event(template_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template_event(%TemplateEvent{} = template_event, attrs) do
    template_event
    |> TemplateEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a TemplateEvent.

  ## Examples

      iex> delete_template_event(template_event)
      {:ok, %TemplateEvent{}}

      iex> delete_template_event(template_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template_event(%TemplateEvent{} = template_event) do
    Repo.delete(template_event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template_event changes.

  ## Examples

      iex> change_template_event(template_event)
      %Ecto.Changeset{source: %TemplateEvent{}}

  """
  def change_template_event(%TemplateEvent{} = template_event) do
    TemplateEvent.changeset(template_event, %{})
  end
end
