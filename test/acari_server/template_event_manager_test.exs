defmodule AcariServer.TemplateEventManagerTest do
  use AcariServer.DataCase

  alias AcariServer.TemplateEventManager

  describe "template_events" do
    alias AcariServer.TemplateEventManager.TemplateEvent

    @valid_attrs %{description: "some description", template: "some template", template_name: "some template_name", username: "some username"}
    @update_attrs %{description: "some updated description", template: "some updated template", template_name: "some updated template_name", username: "some updated username"}
    @invalid_attrs %{description: nil, template: nil, template_name: nil, username: nil}

    def template_event_fixture(attrs \\ %{}) do
      {:ok, template_event} =
        attrs
        |> Enum.into(@valid_attrs)
        |> TemplateEventManager.create_template_event()

      template_event
    end

    test "list_template_events/0 returns all template_events" do
      template_event = template_event_fixture()
      assert TemplateEventManager.list_template_events() == [template_event]
    end

    test "get_template_event!/1 returns the template_event with given id" do
      template_event = template_event_fixture()
      assert TemplateEventManager.get_template_event!(template_event.id) == template_event
    end

    test "create_template_event/1 with valid data creates a template_event" do
      assert {:ok, %TemplateEvent{} = template_event} = TemplateEventManager.create_template_event(@valid_attrs)
      assert template_event.description == "some description"
      assert template_event.template == "some template"
      assert template_event.template_name == "some template_name"
      assert template_event.username == "some username"
    end

    test "create_template_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = TemplateEventManager.create_template_event(@invalid_attrs)
    end

    test "update_template_event/2 with valid data updates the template_event" do
      template_event = template_event_fixture()
      assert {:ok, %TemplateEvent{} = template_event} = TemplateEventManager.update_template_event(template_event, @update_attrs)
      assert template_event.description == "some updated description"
      assert template_event.template == "some updated template"
      assert template_event.template_name == "some updated template_name"
      assert template_event.username == "some updated username"
    end

    test "update_template_event/2 with invalid data returns error changeset" do
      template_event = template_event_fixture()
      assert {:error, %Ecto.Changeset{}} = TemplateEventManager.update_template_event(template_event, @invalid_attrs)
      assert template_event == TemplateEventManager.get_template_event!(template_event.id)
    end

    test "delete_template_event/1 deletes the template_event" do
      template_event = template_event_fixture()
      assert {:ok, %TemplateEvent{}} = TemplateEventManager.delete_template_event(template_event)
      assert_raise Ecto.NoResultsError, fn -> TemplateEventManager.get_template_event!(template_event.id) end
    end

    test "change_template_event/1 returns a template_event changeset" do
      template_event = template_event_fixture()
      assert %Ecto.Changeset{} = TemplateEventManager.change_template_event(template_event)
    end
  end
end
