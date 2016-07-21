defmodule Callisto.CypherTest do
  use ExUnit.Case
  alias Callisto.{Cypher, Edge, Query, Triple, Vertex}

  doctest Cypher
  doctest Query

  describe "for vertex" do
    test "returns string for vertex" do
      attributes = %{name: "Strawberry"}
      labels = [Medicine]
      vertex = Vertex.new(labels, attributes)
      cypher = Cypher.to_cypher(vertex)
      assert is_bitstring(cypher)
    end

    test "returns cypher formated string for vertex" do
      attributes = %{name: "Strawberry"}
      labels = [Medicine]
      vertex = Vertex.new(labels, attributes)
      # {:ok, "(x:Medicine {dose: 100, efficacy: 0.9, is_bitter: false, name: \"Strawberry\"})"}
      cypher = Cypher.to_cypher(vertex)
      "(x:Medicine " <> tail = cypher
      assert String.contains?(tail, "name: 'Strawberry'")
    end
  end

  describe "for edge" do
    test "returns string for edge" do
      edge = Edge.new(HasMedicine)

      cypher = Cypher.to_cypher(edge)
      assert is_bitstring(cypher)
    end
  end

  describe "for random map" do
    test "returns a Vertex" do
      cypher = Cypher.to_cypher(%{foo: "bar"}, "biff")
      assert is_bitstring(cypher)
      assert cypher == "(biff {foo: 'bar'})"

      cypher = Cypher.to_cypher(%{foo: 42}, "biff")
      assert is_bitstring(cypher)
      assert cypher == "(biff {foo: 42})"
    end
  end

  describe "to_string" do
    setup do
      v1 = Vertex.new(Treatment, %{name: "Foo"})
      v2 = Vertex.new(Medicine, %{name: "Bar"})
      e = Edge.new(HasMedicine)
      {:ok, v1: v1, v2: v2, e: e, 
            triple: %Triple{from: v1, to: v2, edge: e} }
    end
    test "vertex", %{v1: v} do
      assert to_string(v) == "(x:Treatment {dose: 50, duration: 1, name: 'Foo'})"
    end

    test "edge", %{e: e} do
      assert to_string(e) == "[x:has_medicine]"
    end

    test "triple", %{triple: t} do
      # Tests that "to_string" makes sense, and to_cypher with no names is
      # the same.
      assert to_string(t) == "(v1:Treatment {dose: 50, duration: 1, name: 'Foo'})-[r:has_medicine]->(v2:Medicine {dose: 100, efficacy: 0.9, is_bitter: false, name: 'Bar'})"
      assert to_string(t) == Cypher.to_cypher(t)

      # Tests that you can set the names as either a list or Keyword list.
      expected = "(from:Treatment {dose: 50, duration: 1, name: 'Foo'})-[edge:has_medicine]->(to:Medicine {dose: 100, efficacy: 0.9, is_bitter: false, name: 'Bar'})"
      assert Cypher.to_cypher(t, ["from", "edge", "to"]) ==  expected
      assert Cypher.to_cypher(t, from: "from", edge: "edge", to: "to") == expected
    end
  end
end
