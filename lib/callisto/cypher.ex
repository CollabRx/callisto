defmodule Callisto.Cypher do
  alias Callisto.Vertex

  @doc ~S"""
    Converts the arguments into Cypher matchers.  If given a struct of any
    kind, attempts to call to_cypher on the struct (so you can define your
    own if you want).  If passed a simple map or keyword list, will presume
    you're looking to match nodes (Vertex) without regard for labels, so
    casts that directly.

      iex> Cypher.to_cypher(%{foo: "bar"})
      "(x {foo: 'bar'})"
      iex> Cypher.to_cypher(%{foo: "bar"}, "biff")
      "(biff {foo: 'bar'})"
      iex> Cypher.to_cypher(Edge.new("wants_a", how_much: "badly"), "r")
      "[r:wants_a {how_much: 'badly'}]"
  """
  def to_cypher(x), do: to_cypher(x, "x")
  def to_cypher(x, name) when is_atom(name), do: to_cypher(x, to_string(name))
  def to_cypher(x=%{__struct__: type}, name), do: type.to_cypher(x, name)
  def to_cypher(x, name) when is_map(x) or is_list(x) do
    Vertex.cast([], Map.new(x))
    |> to_cypher(name)
  end


  @doc ~S"""
    Generates the common "matching" criteria for Cypher.  The only real
    difference between Vertex and Edge matching is whether the matching
    criteria is surrounded by parens (Vertex) or brackets (Edge).

      iex> Cypher.matcher("x", "Foo", %{id: 42, cereal: "BooBerry"})
      "x:Foo {id: 42, cereal: 'BooBerry'}"
  """
  def matcher(name, labels, props) when is_list(labels) != true,
      do: matcher(name, [labels], props)
  def matcher(name, labels, props), do: do_matcher(name, labels, props)
  defp do_matcher(name, labels, props) do
    ["#{name}#{labels_suffix(labels)}", set_values(props)]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  @doc ~S"""
    Escapes the value for insertion into a Cypher string.  We consistently use
    single quotes, so we don't need to escape double quotes.

      iex> Cypher.escape("don't\tstop\nthinking about tomorrow")
      "don\\'t\\tstop\\nthinking about tomorrow"
  """
  def escape(value) when is_binary(value) do
    String.replace(value, "\\", "\\\\") # REPLACE THESE FIRST!
    |> String.replace("'", "\\'")
    |> String.replace("\t", "\\t")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
  end
  def escape(value) when is_nil(value), do: "NULL"
  def escape(value), do: to_string(value)
  def escaped_quote(value) when is_binary(value), do: "'#{escape(value)}'"
  def escaped_quote(value), do: escape(value)

  defp labels_suffix([]), do: ""
  defp labels_suffix(labels) do
    ":" <> Enum.join(labels, ":")
  end

  @doc ~S"""
    Helper for converting a Map/Keyword into the properties block for Cypher,
    which is consistently used in various places (the curly brace containing
    key/value pairs).  Returns empty string if there are no keys.

    NOTE:  If a value is nil, will convert to NULL; if you don't want nil
           values escaped to NULL, use set_not_nil_values
           id key will be in the front

      iex> Cypher.set_values(x: 42, y: "biff", nothing: nil)
      "{nothing: NULL, x: 42, y: 'biff'}"

      iex> Cypher.set_values(%{})
      ""
  """
  def set_values(hash) when is_map(hash) do
    Enum.map(hash, fn({k,v}) ->
      "#{to_string(k)}: #{escaped_quote(v)}"
    end)
    |> Enum.sort_by(fn(a) -> String.match?(a, ~r/^id: /) end, &>=/2)
    |> Enum.join(", ")
    |> case do
      "" -> ""
      stuff -> "{#{stuff}}"
    end
  end
  def set_values(hash) when is_list(hash), do: set_values(Map.new(hash))

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
