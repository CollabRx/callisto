defmodule Callisto.LabelTest do
  use ExUnit.Case

  test "defines properties on label struct" do
    field_names = Map.keys(%Medicine{})
    assert field_names == [:__struct__, :dose, :efficacy, :is_bitter, :name]
  end
end
