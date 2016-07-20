defmodule Callisto.QueryTest do
  use ExUnit.Case
  alias Callisto.{Edge,Query,Vertex}

  test "queries" do
    treatment_attributes = %{name: "Yelling"}
    from_vertex = Vertex.new(Treatment, treatment_attributes)

    edge = Edge.new(HasMedicine)

    {:ok, q1} = Query.create(from_vertex)
    IO.puts q1

    {:ok, q2} = Query.create(edge)
    IO.puts q2
  end
end
