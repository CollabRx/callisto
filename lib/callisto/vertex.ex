defmodule Callisto.Vertex do
  @moduledoc """
    Defines structure for representing a Vertex (node).
  """

  alias __MODULE__
  alias Callisto.{Cypher, Properties}

  defstruct id: nil, props: %{}, labels: [], validators: []
  # NOTE:  id is made "special" here; it's intended to mirror the :id key
  #        from props.

  def to_cypher(v, name \\ "v") do
    "(#{Cypher.matcher(name, v.labels, v.props)})"
  end

  @doc """
    Returns a Vertex with <data> properties, and <labels>.  <labels> is
    expected to be one or more strings or structs that have used Label.
  """
  def new(labels), do: new(labels, %{})
  def new(labels, data) when is_list(data), do: new(labels, Map.new(data))
  def new(labels, data) when is_list(labels) != true, do: new([labels], data)
  def new(labels, data) do
    %{ cast(labels, data) | props: Properties.cast_props(labels, data) }
    |> Properties.denormalize_id
  end

  def cast(labels), do: cast(labels, %{})
  def cast(labels, data) when is_list(data), do: cast(labels, Map.new(data))
  def cast(labels, data) when is_list(labels) != true, do: cast([labels], data)
  def cast(labels, data) do
    %Vertex{validators: labels,
            labels: normalize_labels(labels),
            props: data,
            id: data["id"] || data[:id] }
  end

  defp normalize_labels(labels) when is_list(labels) do
    Enum.map labels, fn(label) ->
      cond do
        is_binary(label) || is_nil(label) -> label
        true -> label.__callisto_properties.name
      end
    end
  end
  defp normalize_labels(labels), do: normalize_labels([labels])

end

defimpl String.Chars, for: Callisto.Vertex do
  def to_string(x), do: Callisto.Vertex.to_cypher(x, "x")
end


