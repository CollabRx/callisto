defmodule Callisto.Triple do
  @moduledoc """
  Defines macros for properties and relationship for an edge linking to vertices
  """
  defstruct from: nil, to: nil, edge: nil
end

defimpl Callisto.Cypherable, for: Callisto.Triple do
  alias Callisto.Cypherable
  def to_cypher(triple, names) when is_list(names) != true do
    to_cypher(triple, ["v1", "r", "v2"])
  end
  def to_cypher(triple, names) when is_list(names) do
    [v1_name, edge_name, v2_name] = names
    with {:ok, v1} <- Cypherable.to_cypher(triple.from, v1_name),
         {:ok, v2} <- Cypherable.to_cypher(triple.to, v2_name),
         {:ok, edge} <- Cypherable.to_cypher(triple.edge, edge_name),
         do: {:ok, "#{v1}-#{edge}->#{v2}"}
  end
end
defimpl String.Chars, for: Callisto.Triple do
  defdelegate to_string(x), to: Callisto.Cypherable.Shared
end

