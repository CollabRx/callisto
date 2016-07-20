defmodule Callisto.PropertiesTest do
  use ExUnit.Case

  alias Callisto.Properties

  test "defines properties on label struct" do
    med = %Medicine{}
    field_names = Map.keys(med)
    assert field_names == [:__struct__, :dose, :efficacy, :id, :is_bitter, :name]
    assert Medicine.__callisto_properties.name == "Medicine"
    assert Properties.__callisto_properties(med).name == "Medicine"
    assert med.dose == 100
  end

  test "defines properties on relationship struct" do
    relationship = struct(HasMedicine)
    field_names = Map.keys(relationship)
    assert field_names == [:__struct__, :amount, :id]
    assert HasMedicine.__callisto_properties.name == "has_medicine"
    assert Properties.__callisto_properties(relationship).name == "has_medicine"
  end

  test "can verify field config" do
    assert Medicine.__callisto_field(:dose) == [type: :integer, default: 100]
    assert Medicine.__callisto_field(:name) == [type: :string, required: true]
  end

  test "defaults id type to :string" do
    assert Medicine.__callisto_properties.id == :string
  end

  test "can pass ID config as parameter" do
    defmodule PropertyTestFoo do
      use Callisto.Properties
      properties [id: nil] do
        field :foo, :string
      end
    end
    assert is_nil(PropertyTestFoo.__callisto_properties.id)
    assert Map.keys(struct(PropertyTestFoo)) == [:__struct__, :foo]
  end

  test "can work without ID config parameter" do
    defmodule PropertyTestBar do
      use Callisto.Properties
      properties do
        field :foo, :string
      end
    end
    assert PropertyTestBar.__callisto_properties.id == :string
    assert Map.keys(struct(PropertyTestBar)) == [:__struct__, :foo, :id]
  end

  test "ID config 'false' doesn't set id in struct" do
    defmodule PropertyTestBiff do
      use Callisto.Properties
      properties id: false do
        field :foo, :string
      end
    end
    assert PropertyTestBiff.__callisto_properties.id == false
    assert Map.keys(struct(PropertyTestBiff)) == [:__struct__, :foo]
  end
end
