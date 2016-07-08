defmodule Callisto.Relationship do
  require Inflex
  defmacro __using__(_) do
    quote do
      import Callisto.Relationship, only: [properties: 1]
      Module.register_attribute(__MODULE__, :callisto_relationship_properties, accumulate: true)
    end
  end

  defmacro properties(do: block) do
    quote do
      try do
        import Callisto.Relationship
        unquote(block)

        attributes = Module.get_attribute(__MODULE__, :callisto_relationship_properties)
        relationship_name = Inflex.underscore(__MODULE__)
        attributes = Keyword.put(attributes, :_callisto_relationship_name, [name: relationship_name])
        defstruct attributes
      after
        :ok
      end
    end
  end

  defmacro field(name, type) do
    options = [type: type]
    quote do
      Module.put_attribute(__MODULE__, :callisto_relationship_properties, {unquote(name), unquote(options)})
    end
  end

  defmacro field(name, type, options) do
    options = [type: type] ++ options
    quote do
      Module.put_attribute(__MODULE__, :callisto_relationship_properties, {unquote(name), unquote(options)})
    end
  end
end
