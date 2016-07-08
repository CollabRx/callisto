defmodule Callisto.Label do
  defmacro __using__(_) do
    quote do
      import Callisto.Label, only: [properties: 1]
      Module.register_attribute(__MODULE__, :callisto_label_properties, accumulate: true)
    end
  end

  defmacro properties(do: block) do
    quote do
      try do
        import Callisto.Label
        unquote(block)

        attributes = Module.get_attribute(__MODULE__, :callisto_label_properties)
        defstruct attributes
      after
        :ok
      end
    end
  end

  defmacro field(name, type) do
    options = [type: type]
    quote do
      Module.put_attribute(__MODULE__, :callisto_label_properties, {unquote(name), unquote(options)})
    end
  end

  defmacro field(name, type, options) do
    options = [type: type] ++ options
    quote do
      Module.put_attribute(__MODULE__, :callisto_label_properties, {unquote(name), unquote(options)})
    end
  end
end
