defmodule Callisto.Edge do
  @moduledoc """
  Defines macros for properties and relationship on edge
  """

  alias __MODULE__

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
    %Edge{relationship: struct(type)._callisto_relationship_name[:name],
          type: type}
    |> cast_props(data)
  end

  # Use the struct given to validate the contents of the properties hash;
  # includes validating given parameters against presence checks, but also
  # defaults the values that are not present.
  defp cast_props(edge = %Edge{type: type}, data) do
    %{edge | props: Map.new(data)
                    |> _atomize_keys(type)
                    |> _validate_required_keys(type)
                    |> _set_defaults(type)
                    |> Enum.map(fn({k, v}) -> _cast_value(k, v, type) end)
                    |> Map.new
     }
  end

  defp _cast_value(key, value, type) do
    relationship_data = struct(type) |> Map.from_struct
    if Map.has_key?(relationship_data, key) do
      definitions = Map.get(relationship_data, key)
      type = definitions[:type]
      {:ok, parsed_value} = Callisto.Type.cast(type, value)
      {key, parsed_value}
    else
      {key, value}
    end
  end

  defp _set_defaults(data, type) do
    relationship_data = struct(type)
    |> Map.from_struct
    |> Enum.filter(fn({_, value}) -> Keyword.has_key?(value, :default) end)
    |> Enum.map(fn({key, value}) -> {key, value[:default]} end)
    |> Map.new

    Map.merge(relationship_data, data)
  end

  defp _atomize_keys(data, type) do
    relationship_keys_to_convert = Map.from_struct(type)
    |> Map.keys
    |> Enum.filter(fn(key) -> Map.has_key?(data, Atom.to_string(key)) end)
    |> Enum.map(&Atom.to_string/1)

    {data_with_string_keys, remaining_data} = Map.split(data, relationship_keys_to_convert)
    map_with_atom_keys = Map.new(data_with_string_keys, fn({key, value}) -> {String.to_atom(key), value} end)
    Map.merge(remaining_data, map_with_atom_keys)
  end

  defp _validate_required_keys(data, type) do
    absent_keys = Map.from_struct(type)
                  |> Enum.filter(fn({_, value}) -> value[:required] == true end)
                  |> Keyword.keys
                  |> Enum.filter(fn(key) -> !Map.has_key?(data, key) end)

    case Enum.count(absent_keys) > 0 do
      true -> raise ArgumentError, "missing required fields: (#{Enum.join(absent_keys, ", ")})"
      _ -> data
    end
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

