defmodule Callisto.PropertiesTest do
  use ExUnit.Case

  alias Callisto.Properties

  test "defines properties on label struct" do
    med = %Medicine{}
    field_names = Map.keys(med)
    assert field_names == [:__struct__, :dose, :efficacy, :is_bitter, :name]
    assert Medicine.__callisto_properties.name == "Medicine"
    assert Properties.__callisto_properties(med).name == "Medicine"
    assert med.dose == 100
  end

  test "defines properties on relationship struct" do
    relationship = struct(HasMedicine)
    field_names = Map.keys(relationship)
    assert field_names == [:__struct__, :amount]
    assert HasMedicine.__callisto_properties.name == "has_medicine"
    assert Properties.__callisto_properties(relationship).name == "has_medicine"
  end

  test "can verify field config" do
    assert Medicine.__callisto_field(:dose) == [type: :integer, default: 100]
    assert Medicine.__callisto_field(:name) == [type: :string, required: true]
  end
end
