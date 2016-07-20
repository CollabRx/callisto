defmodule Callisto.Triple do
  @moduledoc """
  Defines macros for properties and relationship for an edge linking to vertices
  """
  alias __MODULE__
  alias Callisto.{Edge, Vertex}

  defstruct from: nil, to: nil, edge: nil

  def to_cypher(triple, names \\ nil)
  def to_cypher(triple, names) when is_list(names) != true do
    to_cypher(triple, [from: "v1", edge: "r", to: "v2"])
  end
  def to_cypher(triple, names) when is_list(names) do
    name_hash = case Keyword.keyword?(names) do
       true -> names |> Map.new
       false -> Map.merge(%{from: "v1", to: "v2", edge: "r"}, Enum.zip([:from, :edge, :to], names) |> Map.new)
    end
    v1 = Vertex.to_cypher(triple.from, name_hash.from)
    v2 = Vertex.to_cypher(triple.to, name_hash.to)
    edge = Edge.to_cypher(triple.edge, name_hash.edge)
    "#{v1}-#{edge}->#{v2}"
  end

  def new() do
    %Triple{}
  end
end

defimpl String.Chars, for: Callisto.Triple do
  def to_string(x), do: Callisto.Triple.to_cypher(x)
end

