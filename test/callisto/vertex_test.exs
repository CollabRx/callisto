defmodule Callisto.VertexTest do
  use ExUnit.Case

  test "defines props and labels" do
    attributes = %{name: "Flubberanate", dose: "20"}
    expected_props = %{name: "Flubberanate", dose: 20, efficacy: 0.9, is_bitter: false}
    labels = [Medicine]
    vertex = Callisto.Vertex.new(labels, attributes)
    assert vertex.props == expected_props
    assert vertex.labels == ["Medicine"]
  end

  test "converts string keys defined in a label to atoms" do
    attributes = %{"name" => "Flubberanate", "dose" => "20"}
    expected_props = %{name: "Flubberanate", dose: 20, efficacy: 0.9, is_bitter: false}
    labels = [Medicine]
    vertex = Callisto.Vertex.new(labels, attributes)
    assert vertex.props == expected_props
  end

  test "raises an error when required key is not present" do
    attributes = %{"dose" => "20"}
    labels = [Medicine]
    expected_error = "missing required fields: (name)"
    assert_raise ArgumentError, expected_error, fn ->
      Callisto.Vertex.new(labels, attributes)
    end
  end

  test "sets properties not defined in the label" do
    attributes = %{name: "Yodogin", dose: 30, comment: "Totally safe"}
    expected_props = %{name: "Yodogin", dose: 30, comment: "Totally safe", efficacy: 0.9, is_bitter: false}
    labels = [Medicine]
    vertex = Callisto.Vertex.new(labels, attributes)
    assert vertex.props == expected_props
  end

  test "sets properties with no labels" do
    attributes = %{name: "Yodogin", dose: 30, comment: "Totally safe"}
    vertex1 = Callisto.Vertex.new([], attributes)
    assert vertex1.props == attributes
  end

  test "sets default properties for multiple labels" do
    attributes = %{name: "Flamiacin"}
    expected_props = %{name: "Flamiacin", dose: 100, duration: 1, efficacy: 0.9, is_bitter: false}
    labels = [Medicine, Treatment]
    vertex = Callisto.Vertex.new(labels, attributes)
    assert vertex.props == expected_props
  end

  test "supports mix of string and property labels" do
    attributes = %{name: "Flamiacin"}
    expected_props = %{name: "Flamiacin", dose: 100, efficacy: 0.9, is_bitter: false}
    labels = [Medicine, "Treatment"]
    vertex = Callisto.Vertex.new(labels, attributes)
    assert vertex.props == expected_props
    assert vertex.labels == ["Medicine", "Treatment"]
  end
end
