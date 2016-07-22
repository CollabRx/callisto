defmodule Callisto.Type do
  @doc ~S"""
    Casts <term> to type <type>, raises ArgumentError if cast fails.

      iex> Type.cast!(:integer, "42")
      42

      iex> Type.cast!(:string, 42)
      "42"
  """
  def cast!(type, term) do
    case cast(type, term) do
      {:ok, val} -> val
      _ -> raise ArgumentError, "#{inspect term} cannot cast to #{type}"
    end
  end

  @doc ~S"""
    Casts <term> to type <type>.  Returns {:ok, cast} on success, :error
    otherwise.

      iex> Type.cast(:integer, "42")
      {:ok, 42}
 
      iex> Type.cast(:string, 42)
      {:ok, "42"}

      iex> Type.cast(:integer, "Foobar")
      :error
  """
  def cast(:float, term) when is_integer(term), do: {:ok, term + 0.0}
  def cast(:boolean, term) when term in ~w(true 1),  do: {:ok, true}
  def cast(:boolean, term) when term in ~w(false 0), do: {:ok, false}
  def cast(:boolean, term) do
    cond do
      term -> {:ok, true}
      true -> {:ok, false}
    end
  end

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

  def cast(_, term) do
    {:ok, term}
  end
end
