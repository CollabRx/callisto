defmodule Callisto.Properties do
  require Inflex

  alias Callisto.Type

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

        def apply_defaults(x), do: Properties.apply_defaults(x, __MODULE__)
        def validate(x), do: Properties.validate(x, __MODULE__)
        def cast_props(x), do: Properties.cast_props(x, __MODULE__)
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

  @doc """
    Atomizes known keys, and if any keys are missing from the map, adds the
    default value to that key in the map.  Note that this is checking for
    the existence of the key, not the non-nil nature of the value.
  """
  def apply_defaults(data, type) when is_bitstring(type), do: data
  def apply_defaults(data, types) when is_list(types) do
    Enum.reduce(types, data, fn(x, acc) -> apply_defaults(acc, x) end)
  end
  def apply_defaults(data, type) do
    type.__callisto_properties.fields
    |> Enum.filter(fn({_, value}) -> Keyword.has_key?(value, :default) end)
    |> Enum.map(fn({key, value}) -> {key, value[:default]} end)
    |> Map.new
    |> Map.merge(atomize_known_keys(data, type))
  end

  @doc """
    Moves any keys defined as fields in the Properties to their atomic key
    version, if they are in the Map as string keys.  If both exist, the string
    version is copied over the atom version.  The string key is then removed.
    Any unknown keys are left -- either as strings or atoms, as they were
    received.  Since the defined keys are already atoms, this does not
    risk polluting the atom cache, and it's safe to pass random hashes through
    this function.
  """
  def atomize_known_keys(data, type) when is_bitstring(type), do: data
  def atomize_known_keys(data, types) when is_list(types) do
    Enum.reduce(types, data, fn(x, acc) -> atomize_known_keys(acc, x) end)
  end
  def atomize_known_keys(data, type) do
    type.__callisto_properties.fields
    |> Map.keys
    |> Enum.filter(&(Map.has_key?(data, Atom.to_string(&1))))
    |> Enum.reduce(Map.new(data), fn(atom_key, acc) ->
      key = Atom.to_string(atom_key)
      # Write the atomized key (may overwrite existing atom key!)
      Map.put(acc, atom_key, Map.get(data, key))
      |> Map.delete(key) # Then delete the string version of the key.
    end)
  end

  @doc """
    Checks the data against type to make sure all required keys are there,
    either as atoms or strings.  Does NOT convert string keys to atoms.
    Returns {:ok, []} on success, or {:error, [missing_key, ...]} on error.
  """
  def validate(_data, type) when is_bitstring(type), do: {:ok, []}
  def validate(data, types) when is_list(types) do
    Enum.reduce(types, {:ok, []}, fn(t, {status, errors}) ->
      case validate(data, t) do
        {:ok, _} -> {status, errors}
        {_, new_errors} -> {:error, errors ++ new_errors}
      end
    end)
  end
  def validate(data, type) do
    clean_data = atomize_known_keys(data, type)
    type.__callisto_properties.fields
    |> Enum.filter(fn({_, value}) -> value[:required] == true end)
    |> Keyword.keys
    |> Enum.filter(fn(key) -> !Map.has_key?(clean_data, key) end)
    |> case do
      [] -> {:ok, []}
      absent_keys -> {:error, absent_keys}
    end
  end

  @doc """
    Calls validate/2 but returns data if validation passes, raises exception
    otherwise.
  """
  def validate!(data, type) do
    case validate(data, type) do
      {:ok, _} -> data
      {:error, absent_keys} -> raise ArgumentError, "missing required fields: (#{Enum.join(absent_keys, ", ")})"
    end
  end

  defp cast_values(data, type) when is_bitstring(type), do: data
  defp cast_values(data, types) when is_list(types) do
    Enum.reduce(types, data, fn(t, acc) -> cast_values(acc, t) end)
  end
  defp cast_values(data, type) do
    Enum.reduce(type.__callisto_properties.fields, data,
                fn({field, defn}, acc) ->
                  case Map.has_key?(acc, field) do
                    false -> acc
                    _ -> Map.put(acc, field, Type.cast!(defn[:type], acc[field]))
                  end
                end)
  end

  def cast_props(type, data) when is_bitstring(type), do: Map.new(data)
  def cast_props(type, data) do
    Map.new(data)
    |> validate!(type)
    |> apply_defaults(type)
    |> cast_values(type)
  end

end
