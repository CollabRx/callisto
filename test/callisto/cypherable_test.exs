defmodule Callisto.CypherableTest do
  use ExUnit.Case
  alias Callisto.Cypherable

  describe "for vertex" do
    test "returns string for vertex" do
      attributes = %{name: "Strawberry"}
      labels = [Medicine]
      vertex = Callisto.Vertex.cast(attributes, labels: labels)
      {:ok, cypher} = Cypherable.to_cypher(vertex)
      assert is_binary(cypher)
    end

    test "returns cypher formated string for vertex" do
      attributes = %{name: "Strawberry"}
      labels = [Medicine]
      vertex = Callisto.Vertex.cast(attributes, labels: labels)
      # {:ok, "(vertex:Medicine {dose: 100, efficacy: 0.9, is_bitter: false, name: \"Strawberry\"})"}
      {:ok, cypher} = Cypherable.to_cypher(vertex)
      "(vertex:Medicine " <> tail = cypher
      assert String.contains?(tail, "name: \"Strawberry\"")
    end
  end

  describe "for edge" do
    test "returns string for edge" do
      medicine_attributes = %{name: "Lemon Peel"}
      treatment_attributes = %{name: "Yelling"}

      from_vertex = Callisto.Vertex.cast(treatment_attributes, labels: [Treatment])
      to_vertex = Callisto.Vertex.cast(medicine_attributes, labels: [Medicine])
      edge = Callisto.Edge.cast(%{}, from_vertex, to_vertex, relationship: HasMedicine)

      {:ok, cypher} = Cypherable.to_cypher(edge)
      IO.puts cypher
      assert is_binary(cypher)
    end
  end
end
