defmodule Callisto.Triple do
  @moduledoc """
  Defines macros for properties and relationship for an edge linking to vertices
  """
  defstruct from: nil, to: nil, edge: nil

end

defimpl Callisto.Cypherable, for: Callisto.Triple do
  alias Callisto.Cypherable
  def to_cypher(triple, names) when is_list(names) != true do
    to_cypher(triple, [from: "v1", edge: "r", to: "v2"])
  end
  def to_cypher(triple, names) when is_list(names) do
    name_hash = case Keyword.keyword?(names) do
       true -> names |> Map.new
       false -> Map.merge(%{from: nil, to: nil, edge: nil}, Enum.zip([:from, :edge, :to], names) |> Map.new)
    end
    with {:ok, v1} <- Cypherable.to_cypher(triple.from, name_hash.from),
         {:ok, v2} <- Cypherable.to_cypher(triple.to, name_hash.to),
         {:ok, edge} <- Cypherable.to_cypher(triple.edge, name_hash.edge),
         do: {:ok, "#{v1}-#{edge}->#{v2}"}
  end
end
defimpl String.Chars, for: Callisto.Triple do
  defdelegate to_string(x), to: Callisto.Cypherable.Shared
end

