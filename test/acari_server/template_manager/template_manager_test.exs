defmodule AcariServer.TemplateManagerTest do
  use AcariServer.DataCase

  alias AcariServer.TemplateManager

  describe "templates" do
    alias AcariServer.TemplateManager.Template

    @valid_attrs %{description: "some description", name: "some name", template: "some template"}
    @update_attrs %{description: "some updated description", name: "some updated name", template: "some updated template"}
    @invalid_attrs %{description: nil, name: nil, template: nil}

    def template_fixture(attrs \\ %{}) do
      {:ok, template} =
        attrs
        |> Enum.into(@valid_attrs)
        |> TemplateManager.create_template()

      template
    end

    test "list_templates/0 returns all templates" do
      template = template_fixture()
      assert TemplateManager.list_templates() == [template]
    end

    test "get_template!/1 returns the template with given id" do
      template = template_fixture()
      assert TemplateManager.get_template!(template.id) == template
    end

    test "create_template/1 with valid data creates a template" do
      assert {:ok, %Template{} = template} = TemplateManager.create_template(@valid_attrs)
      assert template.description == "some description"
      assert template.name == "some name"
      assert template.template == "some template"
    end

    test "create_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = TemplateManager.create_template(@invalid_attrs)
    end

    test "update_template/2 with valid data updates the template" do
      template = template_fixture()
      assert {:ok, %Template{} = template} = TemplateManager.update_template(template, @update_attrs)
      assert template.description == "some updated description"
      assert template.name == "some updated name"
      assert template.template == "some updated template"
    end

    test "update_template/2 with invalid data returns error changeset" do
      template = template_fixture()
      assert {:error, %Ecto.Changeset{}} = TemplateManager.update_template(template, @invalid_attrs)
      assert template == TemplateManager.get_template!(template.id)
    end

    test "delete_template/1 deletes the template" do
      template = template_fixture()
      assert {:ok, %Template{}} = TemplateManager.delete_template(template)
      assert_raise Ecto.NoResultsError, fn -> TemplateManager.get_template!(template.id) end
    end

    test "change_template/1 returns a template changeset" do
      template = template_fixture()
      assert %Ecto.Changeset{} = TemplateManager.change_template(template)
    end
  end
end
