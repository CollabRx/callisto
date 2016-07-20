defmodule Callisto.PropertiesTest do
  use ExUnit.Case

  test "defines properties on label struct" do
    field_names = Map.keys(%Medicine{})
    assert field_names == [:__struct__, :_callisto_name, :dose, :efficacy, :is_bitter, :name]
  end

  test "defines properties on relationship struct" do
    relationship = struct(HasMedicine)
    field_names = Map.keys(relationship)
    assert field_names == [:__struct__, :_callisto_name, :amount]
    assert relationship._callisto_name[:name] == "has_medicine"
  end
end
