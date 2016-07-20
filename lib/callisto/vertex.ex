defmodule Callisto.Vertex do
  @moduledoc """
    Defines structure for representing a Vertex (node).
  """

  alias __MODULE__
  alias Callisto.{Cypher, Properties}

  defstruct id: nil, props: %{}, labels: [], validators: []
  # NOTE:  id is made "special" here, but its use is non-specific.
  #        In some systems, it could be populated with an internal, persistent
  #        ID that can be used to identify a specific entity in the graph
  #        database, or it could mirror an ID field in the properties, which
  #        is self-managed, or it can just be ignored.

  def to_cypher(v, name \\ "v") do
    "(#{Cypher.matcher(name, v.labels, v.props)})"
  end

  @doc """
    Returns a Vertex with <data> properties, and <labels>.  <labels> is
    expected to be one or more strings or structs that have used Label.
  """
  def new(labels), do: new(labels, [])
  def new(labels, data) when is_map(data), do: new(labels, Map.to_list(data))
  def new(labels, data) when is_list(labels) != true, do: new([labels], data)
  def new(labels, data) do
    %{ cast(labels, data) | 
       props: Enum.reduce(labels, Map.new(data), fn(label, acc) ->
                Properties.cast_props(label, acc)
              end) }
  end

  def cast(labels), do: cast(labels, [])
  def cast(labels, data) when is_map(data), do: cast(labels, Map.to_list(data))
  def cast(labels, data) when is_list(labels) != true, do: cast([labels], data)
  def cast(labels, data) do
    %Vertex{validators: labels,
            labels: normalize_labels(labels),
            props: Map.new(data) }
  end

  defp normalize_labels(labels) when is_list(labels) do
    Enum.map labels, fn(label) ->
      cond do
        is_bitstring(label) -> label
        true -> label.__callisto_properties.name
      end
    end
  end
  defp normalize_labels(labels), do: normalize_labels([labels])

end

defimpl String.Chars, for: Callisto.Vertex do
  def to_string(x), do: Callisto.Vertex.to_cypher(x, "x")
end


