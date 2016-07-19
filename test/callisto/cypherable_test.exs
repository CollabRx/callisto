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
      # {:ok, "(x:Medicine {dose: 100, efficacy: 0.9, is_bitter: false, name: \"Strawberry\"})"}
      {:ok, cypher} = Cypherable.to_cypher(vertex)
      "(x:Medicine " <> tail = cypher
      assert String.contains?(tail, "name: \"Strawberry\"")
    end
  end

  describe "for edge" do
    test "returns string for edge" do
      edge = Callisto.Edge.new(HasMedicine)

      {:ok, cypher} = Cypherable.to_cypher(edge)
      assert is_binary(cypher)
    end
  end

  describe "to_string" do
    setup do
      v1 = Callisto.Vertex.cast(%{name: "Foo"}, labels: [Treatment])
      v2 = Callisto.Vertex.cast(%{name: "Bar"}, labels: [Medicine])
      e = Callisto.Edge.new(HasMedicine)
      {:ok, v1: v1, v2: v2, e: e, 
            triple: %Callisto.Triple{from: v1, to: v2, edge: e} }
    end
    test "vertex", %{v1: v} do
      assert to_string(v) == "(x:Treatment {dose: 50, duration: 1, name: \"Foo\"})"
    end

    test "edge", %{e: e} do
      assert to_string(e) == "[x:has_medicine {}]"
    end

    test "triple", %{triple: t} do
      assert to_string(t) == "(v1:Treatment {dose: 50, duration: 1, name: \"Foo\"})-[r:has_medicine {}]->(v2:Medicine {dose: 100, efficacy: 0.9, is_bitter: false, name: \"Bar\"})"
      assert to_string(t) == Cypherable.to_cypher!(t)
      assert Cypherable.to_cypher!(t, ["from", "edge", "to"]) == "(from:Treatment {dose: 50, duration: 1, name: \"Foo\"})-[edge:has_medicine {}]->(to:Medicine {dose: 100, efficacy: 0.9, is_bitter: false, name: \"Bar\"})"
    end
  end
end
