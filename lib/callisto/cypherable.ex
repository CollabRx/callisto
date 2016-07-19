defprotocol Callisto.Cypherable do
  def to_cypher(x, name)
  defdelegate to_cypher!(x, name), to: Callisto.Cypherable.Shared
  defdelegate to_cypher(x), to: Callisto.Cypherable.Shared
  defdelegate to_cypher!(x), to: Callisto.Cypherable.Shared
end

# Methods common to all Cypherables.
defmodule Callisto.Cypherable.Shared do
  alias Callisto.Cypherable

  def to_cypher!(x, name) do
    {:ok, str} = Cypherable.to_cypher(x, name)
    str
  end
  def to_cypher(x), do: Cypherable.to_cypher(x, "x")
  def to_cypher!(x), do: to_cypher!(x, "x")

  def matcher(name, labels, props) when is_bitstring(labels),
      do: matcher(name, [labels], props)
  def matcher(name, labels, props) do
    name <> labels_suffix(labels) <> props_str(props)
  end

  defp labels_suffix([]), do: ""
  defp labels_suffix(labels) do
    ":" <> Enum.join(labels, ":")
  end

  defp props_str([]), do: ""
  defp props_str(props) do
    props_string = Enum.map_join(props, ", ", fn({key, value}) ->
      if is_binary(value) do
        "#{key}: \"#{value}\""
      else
        "#{key}: #{value}"
      end
    end)
    " {#{props_string}}"
  end

  def to_string(x) do
    {:ok, str} = Cypherable.to_cypher(x, "x")
    str
  end
end

