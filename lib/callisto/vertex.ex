defmodule Callisto.Vertex do
  defstruct props: %{}, labels: []

  def cast(data), do: cast(data, labels: [])
  def cast(data, labels: labels) do
    labels = _atomize_labels(labels)
    props = _cast_props(data, labels)
    %Callisto.Vertex{props: props, labels: _atoms_to_strings(labels)}
  end

  defp _cast_props(data, labels) do
    data = _atomize_keys(data, labels)
    _validate_required_keys(data, labels)
    data_with_defauts = _set_defaults(data, labels)
    Map.new(data_with_defauts, fn({key, value}) -> _cast_value(key, value, labels) end)
  end

  defp _cast_value(key, value, labels) do
    labels_with_key = labels |> Enum.filter(fn(label) ->
      struct(label) |> Map.from_struct |> Map.has_key?(key)
    end)
    if Enum.count(labels_with_key) == 0 do
      {key, value}
    else
      # Grab the last label.
      label = Enum.at(labels_with_key, -1) |> struct
      definitions = Map.get(label, key)
      type = definitions[:type]
      {:ok, parsed_value} = Callisto.Type.cast(type, value)
      {key, parsed_value}
    end
  end

  defp _set_defaults(data, [label|tail]) do
    label_data = Map.from_struct(label)
    |> Enum.filter(fn({_, value}) -> Keyword.has_key?(value, :default) end)
    |> Enum.map(fn({key, value}) -> {key, value[:default]} end)
    |> Map.new

    data = Map.merge(label_data, data)
    _set_defaults(data, tail)
  end

  defp _set_defaults(data, []), do: data

  defp _atomize_keys(data, [label|tail]) do
    label_keys_to_convert = Map.from_struct(label)
    |> Map.keys
    |> Enum.filter(fn(key) -> Map.has_key?(data, Atom.to_string(key)) end)
    |> Enum.map(&Atom.to_string/1)

    {data_with_string_keys, remaining_data} = Map.split(data, label_keys_to_convert)
    map_with_atom_keys = Map.new(data_with_string_keys, fn({key, value}) -> {String.to_atom(key), value} end)
    data = Map.merge(remaining_data, map_with_atom_keys)
    _atomize_keys(data, tail)
  end

  defp _atomize_keys(data, []), do: data

  defp _validate_required_keys(data, labels, absent_keys \\ [])
  defp _validate_required_keys(data, [label|tail], absent_keys) do
    current_absent_keys = Map.from_struct(label)
    |> Enum.filter(fn({_, value}) -> value[:required] == true end)
    |> Keyword.keys
    |> Enum.filter(fn(key) -> !Map.has_key?(data, key) end)

    absent_keys = absent_keys ++ current_absent_keys
    _validate_required_keys(data, tail, absent_keys)
  end

  defp _validate_required_keys(_, [], absent_keys) do
    if Enum.count(absent_keys) > 0 do
      raise ArgumentError, "missing required fields: (#{Enum.join(absent_keys, ", ")})"
    end
  end

  defp _atoms_to_strings(atoms) do
    atoms |> Enum.map(&_atom_to_string(&1))
  end

  defp _atom_to_string(atom) do
    "Elixir." <> label = Atom.to_string(atom)
    label
  end

  defp _atomize_labels(labels) do
    if Enum.all?(labels, fn(label) -> is_bitstring(label) end) do
      labels
      |> Enum.map(fn(label) -> String.to_atom("Elixir.#{label}") end)
    else
      labels
    end
  end
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


