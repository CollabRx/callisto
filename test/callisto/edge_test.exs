defmodule Callisto.EdgeTest do
  use ExUnit.Case

  test "edge cast with expected attributes" do
    medicine_attributes = %{name: "Lemon Peel"}
    treatment_attributes = %{name: "Yelling"}

    from_vertex = Callisto.Vertex.cast(treatment_attributes, labels: [Treatment])
    to_vertex = Callisto.Vertex.cast(medicine_attributes, labels: [Medicine])
    edge = Callisto.Edge.cast(%{}, from_vertex, to_vertex, relationship: HasMedicine)

    assert is_map(edge.props)
  end

  test "converts string keys defined in a relationship to atoms" do
    attributes = %{"name" => "Water", "amount" => "20"}
    medicine_attributes = %{name: "Lemon Peel"}
    treatment_attributes = %{name: "Yelling"}

    from_vertex = Callisto.Vertex.cast(treatment_attributes, labels: [Treatment])
    to_vertex = Callisto.Vertex.cast(medicine_attributes, labels: [Medicine])
    edge = Callisto.Edge.cast(attributes, from_vertex, to_vertex, relationship: HasMedicine)
    expected_props = %{"name" => "Water", amount: 20}

    assert edge.props == expected_props
  end
end
