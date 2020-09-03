defmodule AcariServer.FilterManagerTest do
  use AcariServer.DataCase

  alias AcariServer.FilterManager

  describe "filrers" do
    alias AcariServer.FilterManager.Filter

    @valid_attrs %{common: true, description: "some description", filter: "some filter"}
    @update_attrs %{common: false, description: "some updated description", filter: "some updated filter"}
    @invalid_attrs %{common: nil, description: nil, filter: nil}

    def filter_fixture(attrs \\ %{}) do
      {:ok, filter} =
        attrs
        |> Enum.into(@valid_attrs)
        |> FilterManager.create_filter()

      filter
    end

    test "list_filters/0 returns all filrers" do
      filter = filter_fixture()
      assert FilterManager.list_filters() == [filter]
    end

    test "get_filter!/1 returns the filter with given id" do
      filter = filter_fixture()
      assert FilterManager.get_filter!(filter.id) == filter
    end

    test "create_filter/1 with valid data creates a filter" do
      assert {:ok, %Filter{} = filter} = FilterManager.create_filter(@valid_attrs)
      assert filter.common == true
      assert filter.description == "some description"
      assert filter.filter == "some filter"
    end

    test "create_filter/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FilterManager.create_filter(@invalid_attrs)
    end

    test "update_filter/2 with valid data updates the filter" do
      filter = filter_fixture()
      assert {:ok, %Filter{} = filter} = FilterManager.update_filter(filter, @update_attrs)
      assert filter.common == false
      assert filter.description == "some updated description"
      assert filter.filter == "some updated filter"
    end

    test "update_filter/2 with invalid data returns error changeset" do
      filter = filter_fixture()
      assert {:error, %Ecto.Changeset{}} = FilterManager.update_filter(filter, @invalid_attrs)
      assert filter == FilterManager.get_filter!(filter.id)
    end

    test "delete_filter/1 deletes the filter" do
      filter = filter_fixture()
      assert {:ok, %Filter{}} = FilterManager.delete_filter(filter)
      assert_raise Ecto.NoResultsError, fn -> FilterManager.get_filter!(filter.id) end
    end

    test "change_filter/1 returns a filter changeset" do
      filter = filter_fixture()
      assert %Ecto.Changeset{} = FilterManager.change_filter(filter)
    end
  end
end
