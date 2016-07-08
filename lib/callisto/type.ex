defmodule Callisto.Type do
  def cast(:float, term) when is_integer(term), do: {:ok, term + 0.0}
  def cast(:boolean, term) when term in ~w(true 1),  do: {:ok, true}
  def cast(:boolean, term) when term in ~w(false 0), do: {:ok, false}

  def cast(:integer, term) when is_binary(term) do
    case Integer.parse(term) do
      {int, ""} -> {:ok, int}
      _         -> :error
    end
  end

  def cast(:float, term) when is_binary(term) do
    case Float.parse(term) do
      {float, ""} -> {:ok, float}
      _         -> :error
    end
  end

  def cast(:string, term) when is_binary(term), do: {:ok, term}
  def cast(:string, term), do: {:ok, to_string(term)}

  def cast(type, term) do
    {:ok, term}
  end
end
