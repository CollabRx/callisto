defmodule Callisto.VertexTest do
  use ExUnit.Case

  alias Callisto.Vertex

  test "defines props and labels" do
    attributes = %{name: "Flubberanate", dose: "20"}
    expected_props = %{name: "Flubberanate", dose: 20, efficacy: 0.9, is_bitter: false}
    labels = [Medicine]
    vertex = Vertex.new(labels, attributes)
    assert vertex.props == expected_props
    assert vertex.labels == ["Medicine"]
  end

  test "can represent unstructured nodes" do
    vert = Vertex.new(["Foo", "Bar"], biff: 42, boom: "flubber")
    assert vert.props == %{biff: 42, boom: "flubber"}
    assert vert.labels == ["Foo", "Bar"]
    assert Vertex.to_cypher(vert) == "(v:Foo:Bar {biff: 42, boom: 'flubber'})"
  end

  test "can accept a map for data" do
    vert = Vertex.new([], %{foo: 42, biff: "boom"})
    assert vert.props == %{foo: 42, biff: "boom"}
    assert Vertex.to_cypher(vert) == "(v {biff: 'boom', foo: 42})"
  end

  test "can take string keys" do
    vert = Vertex.new([], %{"foo" => 42})
    assert vert.props == %{"foo" => 42}
    assert Vertex.to_cypher(vert) == "(v {foo: 42})"
  end

  test "converts only the hash keys that are fields" do
    vert = Vertex.new(Medicine, %{"foo" => 42, "name" => "flubber"})
    assert %{"foo" => foo, name: name} = vert.props
    assert foo == 42
    assert name == "flubber"
  end

  test "converts string keys defined in a label to atoms" do
    attributes = %{"name" => "Flubberanate", "dose" => "20"}
    expected_props = %{name: "Flubberanate", dose: 20, efficacy: 0.9, is_bitter: false}
    labels = [Medicine]
    vertex = Vertex.new(labels, attributes)
    assert vertex.props == expected_props
  end

  test "raises an error when required key is not present" do
    attributes = %{"dose" => "20"}
    labels = [Medicine]
    expected_error = "missing required fields: (name)"
    assert_raise ArgumentError, expected_error, fn ->
      Vertex.new(labels, attributes)
    end
  end

  test "sets properties not defined in the label" do
    attributes = %{name: "Yodogin", dose: 30, comment: "Totally safe"}
    expected_props = %{name: "Yodogin", dose: 30, comment: "Totally safe", efficacy: 0.9, is_bitter: false}
    labels = [Medicine]
    vertex = Vertex.new(labels, attributes)
    assert vertex.props == expected_props
  end

  test "sets properties with no labels" do
    attributes = %{name: "Yodogin", dose: 30, comment: "Totally safe"}
    vertex1 = Vertex.new([], attributes)
    assert vertex1.props == attributes
  end

  test "sets default properties for multiple labels" do
    attributes = %{name: "Flamiacin"}
    expected_props = %{name: "Flamiacin", dose: 100, duration: 1, efficacy: 0.9, is_bitter: false}
    labels = [Medicine, Treatment]
    vertex = Vertex.new(labels, attributes)
    assert vertex.props == expected_props
  end

  test "supports mix of string and property labels" do
    attributes = %{name: "Flamiacin"}
    expected_props = %{name: "Flamiacin", dose: 100, efficacy: 0.9, is_bitter: false}
    labels = [Medicine, "Treatment"]
    vertex = Vertex.new(labels, attributes)
    assert vertex.props == expected_props
    assert vertex.labels == ["Medicine", "Treatment"]
  end
end
