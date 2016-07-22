defmodule Callisto.EdgeTest do
  use ExUnit.Case

  alias Callisto.Edge

  doctest Edge

  test "edge cast with expected attributes" do
    edge = Edge.new(HasMedicine)
    assert is_map(edge.props)
  end

  test "converts string keys defined in a relationship to atoms" do
    attributes = %{"name" => "Water", "amount" => "20"}
    edge = Edge.new(HasMedicine, attributes)
    expected_props = %{"name" => "Water", amount: 20}
    assert edge.props == expected_props
  end
end
