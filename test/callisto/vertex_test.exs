defmodule Callisto.VertexTest do
  use ExUnit.Case

  alias Callisto.Vertex

  doctest Vertex

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

  test "can take keywords" do
    vert = Vertex.new(Medicine, name: "Flubberanate", dose: "20")
    expected_cypher = "(v:Medicine {dose: 20, efficacy: 0.9, is_bitter: false, name: 'Flubberanate'})"
    actual_cypher = Vertex.to_cypher(vert)
    assert expected_cypher == actual_cypher
  end

  test "can take keywords with id present" do
    vert = Vertex.new(Medicine, id: "1000", name: "Flubberanate", dose: "20")
    expected_cypher = "(v:Medicine {id: '1000', dose: 20, efficacy: 0.9, is_bitter: false, name: 'Flubberanate'})"
    actual_cypher = Vertex.to_cypher(vert)
    assert expected_cypher == actual_cypher
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

  test "converts defined property keys from strings to atoms" do
    attributes = %{"name" => "Flamiacin"}
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

  describe "auto ID assignment" do
    test "Properties that define id as UUID will auto-assign value unless set" do
      defmodule AutoID do
        use Callisto.Properties
        properties id: :uuid do
          field :thing, :string
        end
      end

      assert AutoID.__callisto_properties.id == :uuid

      v = Vertex.new(AutoID)
      assert v.id, inspect(v)

      %Vertex{id: id, props: props} = Vertex.new(AutoID, id: "foo")
      assert props.id == "foo"
      assert id == "foo"
    end

    test "Properties that defined a function for UUID work" do
      defmodule FuncID do
        use Callisto.Properties
        def uuid(_obj), do: "foo"
        properties id: &FuncID.uuid/1 do
          field :thing, :string
        end
      end

      assert is_function(FuncID.__callisto_properties.id)
      v = Vertex.new(FuncID)
      assert v.id == "foo", inspect(v)

      v = Vertex.new(FuncID, id: "bar")
      assert v.id == "bar", inspect(v)
    end
  end

end
