defmodule Callisto.Vertex do
  @moduledoc """
    Defines structure for representing a Vertex (node).
  """

  alias __MODULE__
  alias Callisto.Properties

  defstruct props: %{}, labels: [], validators: []

  @doc """
    Returns a Vertex with <data> properties, and <labels>.  <labels> is
    expected to be one or more strings or structs that have used Label.
  """
  def new(labels), do: new(labels, [])
  def new(labels, data) when is_map(data), do: new(labels, Map.to_list(data))
  def new(labels, data) when is_list(labels) != true, do: new([labels], data)
  def new(labels, data) do
    %Vertex{validators: labels,
            labels: normalize_labels(labels),
            props: Enum.reduce(labels, Map.new(data), fn(label, acc) ->
                     Properties.cast_props(label, acc)
                   end) }
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

defimpl Callisto.Cypherable, for: Callisto.Vertex do
  alias Callisto.Cypherable.Shared
  def to_cypher(vertex, vertex_name \\ "vertex") do
    {:ok, "(" <> Shared.matcher(vertex_name, vertex.labels, vertex.props) <> ")" }
  end
end
defimpl String.Chars, for: Callisto.Vertex do
  defdelegate to_string(x), to: Callisto.Cypherable.Shared
end


