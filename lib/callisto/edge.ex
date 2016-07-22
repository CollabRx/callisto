defmodule Callisto.Edge do
  @moduledoc """
    Defines structure for representing an Edge (relationship)
  """

  alias __MODULE__
  alias Callisto.{Cypher, Properties}

  defstruct id: nil, props: %{}, relationship: nil, type: nil
  # NOTE:  id is made "special" here; it's intended to mirror the :id key
  #        from props

  def to_cypher(e, name \\ "r") do
    "[#{Cypher.matcher(name, e.relationship, e.props)}]"
  end

  @doc """
    Returns an Edge with <data> properties, and <type> set.  If <type> is
    a module, will use that to validate the properties and define the name.
    If <type> is a string, that will be the name of the edge type.
  """
  def new(type), do: new(type, %{})
  def new(type, data) do
    %{cast(type, data) | props: Properties.cast_props(type, data) }
    |> Properties.denormalize_id
  end

  @doc """
    Returns an Edge with discoverable properties, but doesn't apply any
    type defaults or validation.  See new/2.
  """
  def cast(type), do: cast(type, %{})
  def cast(type, data) when is_list(data), do: cast(type, Map.new(data))
  def cast(type, data) when is_bitstring(type) do
    %Edge{props: data, relationship: type, id: data["id"] || data[:id]}
  end
  def cast(type, data) when is_atom(type) do
    %Edge{relationship: type.__callisto_properties.name,
          type: type, props: data, id: data["id"] || data[:id]}
  end
end

defimpl String.Chars, for: Callisto.Edge do
  def to_string(x), do: Callisto.Edge.to_cypher(x, "x")
end

