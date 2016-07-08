defmodule Callisto.Edge do
  @moduledoc """
  Defines macros for properties and relationship on edge
  """
  defstruct props: %{}, from: nil, to: nil, relationship: nil

  def cast(data, from_vertex, to_vertex, relationship: relationship) do
    relationship_name = _stringify_relationship(relationship)
    props = _cast_props(data, relationship)
    %Callisto.Edge{props: props, from: from_vertex, to: to_vertex, relationship: relationship_name}
  end

  defp _cast_props(data, relationship) do
    data = _atomize_keys(data, relationship)
    if is_atom(relationship) do
      _validate_required_keys(data, relationship)
    end
    data_with_defauts = _set_defaults(data, relationship)
    Map.new(data_with_defauts, fn({key, value}) -> _cast_value(key, value, relationship) end)
  end

  defp _cast_value(key, value, relationship) do
    relationship_data = struct(relationship) |> Map.from_struct
    if Map.has_key?(relationship_data, key) do
      definitions = Map.get(relationship_data, key)
      type = definitions[:type]
      {:ok, parsed_value} = Callisto.Type.cast(type, value)
      {key, parsed_value}
    else
      {key, value}
    end
  end

  defp _set_defaults(data, relationship) do
    relationship_data = struct(relationship)
    |> Map.from_struct
    |> Enum.filter(fn({_, value}) -> Keyword.has_key?(value, :default) end)
    |> Enum.map(fn({key, value}) -> {key, value[:default]} end)
    |> Map.new

    Map.merge(relationship_data, data)
  end

  defp _atomize_keys(data, relationship) do
    relationship_keys_to_convert = Map.from_struct(relationship)
    |> Map.keys
    |> Enum.filter(fn(key) -> Map.has_key?(data, Atom.to_string(key)) end)
    |> Enum.map(&Atom.to_string/1)

    {data_with_string_keys, remaining_data} = Map.split(data, relationship_keys_to_convert)
    map_with_atom_keys = Map.new(data_with_string_keys, fn({key, value}) -> {String.to_atom(key), value} end)
    Map.merge(remaining_data, map_with_atom_keys)
  end

  defp _validate_required_keys(data, relationship, absent_keys \\ [])
  defp _validate_required_keys(data, relationship, absent_keys) do
    current_absent_keys = Map.from_struct(relationship)
    |> Enum.filter(fn({_, value}) -> value[:required] == true end)
    |> Keyword.keys
    |> Enum.filter(fn(key) -> !Map.has_key?(data, key) end)

    absent_keys = absent_keys ++ current_absent_keys
    if Enum.count(absent_keys) > 0 do
      raise ArgumentError, "missing required fields: (#{Enum.join(absent_keys, ", ")})"
    end
  end

  defp _stringify_relationship(relationship) do
    if is_atom(relationship) do
      struct(relationship)._callisto_relationship_name[:name]
    else
      relationship
    end
  end
end
