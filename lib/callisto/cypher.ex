defmodule Callisto.Cypher do
  alias Callisto.Vertex

  def to_cypher(x), do: to_cypher(x, "x")
  def to_cypher(x, name) when is_atom(name), do: to_cypher(x, to_string(name))
  def to_cypher(x=%{__struct__: type}, name), do: type.to_cypher(x, name)
  def to_cypher(x, name) when is_map(x) or is_list(x) do
    Vertex.cast([], Map.new(x))
    |> to_cypher(name)
  end
  

  def matcher(name, labels, props) when is_list(labels) != true,
      do: matcher(name, [labels], props)
  def matcher(name, labels, props) do
    ["#{name}#{labels_suffix(labels)}", set_values(props)]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  def escape(value) when is_bitstring(value) do
    String.replace(value, "'", "\\'")
  end
  def escape(value) when is_nil(value), do: "NULL"
  def escape(value), do: to_string(value)
  def escaped_quote(value) when is_bitstring(value), do: "'#{escape(value)}'"
  def escaped_quote(value), do: escape(value)

  defp labels_suffix([]), do: ""
  defp labels_suffix(labels) do
    ":" <> Enum.join(labels, ":")
  end

  @doc ~S"""
    Helper for converting a Map/Keyword into the properties block for Cypher,
    which is consistently used in various places (the curly brace containing
    key/value pairs).  Returns empty string if there are no keys.

      iex> Cypher.set_values(x: 42, y: "biff")
      "{x: 42, y: 'biff'}"

      iex> Cypher.set_values(%{})
      ""
  """
  def set_values(kwlist) when is_list(kwlist) do
    Enum.map_join(kwlist, ", ", fn({k,v}) ->
      "#{to_string(k)}: #{escaped_quote(v)}"
    end)
    |> case do
      "" -> ""
      stuff -> "{#{stuff}}"
    end
  end
  def set_values(hash) when is_map(hash), do: set_values(Map.to_list(hash))

  @doc ~S"""
    Like set_values/1 but does not include any keys where the value is nil.

      iex> Cypher.set_not_nil_values(x: 42, y: "biff", z: nil)
      "{x: 42, y: 'biff'}"

      iex> Cypher.set_not_nil_values(%{foo: nil})
      ""
  """
  def set_not_nil_values(kwlist) when is_list(kwlist) do
    Enum.reject(kwlist, fn({_,v}) -> is_nil(v) end)
    |> set_values
  end
  def set_not_nil_values(hash) when is_map(hash) do
    Map.to_list(hash) |> set_not_nil_values
  end

end

