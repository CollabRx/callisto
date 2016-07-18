defmodule Callisto.QueryTest do
  use ExUnit.Case

  test "queries" do
    medicine_attributes = %{name: "Lemon Peel"}
    treatment_attributes = %{name: "Yelling"}

    from_vertex = Callisto.Vertex.cast(treatment_attributes, labels: [Treatment])
    to_vertex = Callisto.Vertex.cast(medicine_attributes, labels: [Medicine])
    edge = Callisto.Edge.cast(%{}, from_vertex, to_vertex, relationship: HasMedicine)

    {:ok, q1} = Callisto.Query.create(from_vertex)
    IO.puts q1

    {:ok, q2} = Callisto.Query.create(edge)
    IO.puts q2
  end
end
