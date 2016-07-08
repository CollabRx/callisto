defmodule Callisto.RelationshipTest do
  use ExUnit.Case

  test "defines properties on relationship struct" do
    relationship = struct(HasMedicine)
    field_names = Map.keys(relationship)
    assert field_names == [:__struct__, :_callisto_relationship_name, :amount]
    assert relationship._callisto_relationship_name[:name] == "has_medicine"
  end
end
