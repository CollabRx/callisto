defmodule Callisto.Properties do
  require Inflex
  defmacro __using__(_) do
    quote do
      import Callisto.Properties, only: [properties: 2, properties: 1]
      Module.register_attribute(__MODULE__, :callisto_properties, accumulate: false)
    end
  end

  defmacro properties(options \\ [id: :string], [do: block]) do
    id_option = Keyword.get(options, :id, :string)
    quote do
      try do
        import Callisto.Properties
        default_name = to_string(__MODULE__ )
                       |> String.split(".")
                       |> List.last
                       |> Inflex.camelize
        props = Module.put_attribute(__MODULE__, :callisto_properties,
                                     %{name: default_name, fields: %{} })

        unquote(block)

        attrs = Module.get_attribute(__MODULE__, :callisto_properties)
                |> Map.merge(%{id: unquote(id_option)}) 
        default_args = if unquote(id_option), do: [{:id, nil}], else: []
        args = Enum.reduce(attrs.fields, default_args,
                           fn({k, v}, acc) ->
          acc ++ [{k, Keyword.get(v, :default)}]
        end)
        @callisto_properties attrs
        def __callisto_properties(), do: @callisto_properties
        def __callisto_field(field), do: @callisto_properties.fields[field]

        defstruct args
      after
        :ok
      end
    end
  end
  def __callisto_properties(arg), do: arg.__struct__.__callisto_properties
  def __callisto_field(arg, field), do: __callisto_properties(arg).fields[field]

  defmacro name(name) do
    quote do
      new_props = Module.get_attribute(__MODULE__, :callisto_properties)
                  |> Map.merge(%{name: unquote(name)})
      Module.put_attribute(__MODULE__, :callisto_properties, new_props)
    end
  end
    

  defmacro field(name, type, options \\ []) do
    options = [type: type] ++ options
    quote do
      props = Module.get_attribute(__MODULE__, :callisto_properties)
      new_props = Map.put(props, :fields, Map.put(props.fields, unquote(name), unquote(options)))
      Module.put_attribute(__MODULE__, :callisto_properties, new_props)
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
    definition = type.__callisto_properties.fields
                 |> Map.get(key, %{})
                 |> Map.new
    {:ok, parsed_value} = Callisto.Type.cast(definition[:type], value)
    {key, parsed_value}
  end

  defp _set_defaults(data, type) do
    type.__callisto_properties.fields
    |> Enum.filter(fn({_, value}) -> Keyword.has_key?(value, :default) end)
    |> Enum.map(fn({key, value}) -> {key, value[:default]} end)
    |> Map.new
    |> Map.merge(data)
  end

  # To avoid leaking atoms, we only atomize those keys that are a) not
  # already atoms, and b) referenced by the type.
  defp _atomize_keys(data, type) do
    type.__callisto_properties.fields
    |> Map.keys
    |> Enum.filter(&(Map.has_key?(data, Atom.to_string(&1))))
    |> Enum.reduce(Map.new(data), fn(atom_key, acc) ->
      key = Atom.to_string(atom_key)
      Map.put(acc, atom_key, Map.get(data, key))
      |> Map.delete(key)
    end)
  end

  defp _validate_required_keys(data, type) do
    type.__callisto_properties.fields
    |> Enum.filter(fn({_, value}) -> value[:required] == true end)
    |> Keyword.keys
    |> Enum.filter(fn(key) -> !Map.has_key?(data, key) end)
    |> case do
      [] -> data
      absent_keys -> raise ArgumentError, "missing required fields: (#{Enum.join(absent_keys, ", ")})"
    end
  end

end
