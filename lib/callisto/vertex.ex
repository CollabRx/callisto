defmodule Callisto.Vertex do
  @moduledoc """
    Defines structure for representing a Vertex (node).
  """

  alias __MODULE__
  alias Callisto.{Cypher, Properties}

  defstruct props: %{}, labels: [], validators: []

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
        true -> struct(label)._callisto_name[:name]
      end
    end
  end
  defp normalize_labels(labels), do: normalize_labels([labels])
end

defimpl String.Chars, for: Callisto.Vertex do
  def to_string(x), do: Callisto.Vertex.to_cypher(x, "x")
end


