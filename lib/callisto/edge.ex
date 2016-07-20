defmodule Callisto.Edge do
  @moduledoc """
    Defines structure for representing an Edge (relationship)
  """

  alias __MODULE__
  alias Callisto.Properties

  defstruct props: %{}, relationship: nil, type: nil

  @doc """
    Returns an Edge with <data> properties, and <type> set.  If <type> is
    a module, will use that to validate the properties and define the name.
    If <type> is a string, that will be the name of the edge type.
  """
  def new(type), do: new(type, [])
  def new(type, data) when is_map(data), do: new(type, Map.to_list(data))
  def new(type, data) when is_bitstring(type) do
    %Edge{props: data, relationship: type}
  end
  def new(type, data) when is_atom(type) do
    %Edge{relationship: struct(type)._callisto_name[:name],
          type: type, props: Properties.cast_props(type, data)}
  end
end

defimpl Callisto.Cypherable, for: Callisto.Edge do
  alias Callisto.Cypherable.Shared
  def to_cypher(edge, edge_name \\ "edge") do
    {:ok, "[" <> Shared.matcher(edge_name, edge.relationship, edge.props) <> "]" }
  end
end
defimpl String.Chars, for: Callisto.Edge do
  defdelegate to_string(x), to: Callisto.Cypherable.Shared
end

