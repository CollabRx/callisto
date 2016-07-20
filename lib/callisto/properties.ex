defmodule Callisto.Properties do
  require Inflex
  defmacro __using__(_) do
    quote do
      import Callisto.Properties, only: [properties: 1]
      Module.register_attribute(__MODULE__, :callisto_properties, accumulate: true)
    end
  end

  defmacro properties(do: block) do
    quote do
      try do
        import Callisto.Properties
        unquote(block)

        propname = Inflex.camelize(__MODULE__ |> to_string |> String.split(".") |> List.last)
        attrs = Module.get_attribute(__MODULE__, :callisto_properties)
        case Keyword.get(attrs, :_callisto_name, nil) do
          nil -> Keyword.put(attrs, :_callisto_name, [name: propname])
          _ -> attrs
        end |> defstruct
      after
        :ok
      end
    end
  end

  defmacro name(name) do
    quote do
      Module.put_attribute(__MODULE__, :callisto_properties, {:_callisto_name, [name: unquote(name)]})
    end
  end
    

  defmacro field(name, type, options \\ []) do
    options = [type: type] ++ options
    quote do
      Module.put_attribute(__MODULE__, :callisto_properties, {unquote(name), unquote(options)})
    end
  end

  def cast_props(type, data) when is_bitstring(type), do: Map.new(data)
  def cast_props(type, data) do
    Map.new(data)
    |> _atomize_keys(type)
    |> _validate_required_keys(type)
    |> _set_defaults(type)
    |> Enum.map(fn({k,v}) -> _cast_value(k, v, type) end)
    |> Map.new
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
    relationship_keys_to_convert =
       Map.from_struct(type)
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
