defmodule Callisto.Query do
  alias __MODULE__
  alias Callisto.{Cypher, Vertex}

  defstruct create: nil,
            match: nil,
            merge: nil,
            where: nil,
            set: nil,
            delete: nil,
            order: nil,
            limit: nil,
            return: nil

  def new do
    %Query{}
  end

  # Accept the match criteria directly.  Only strings supported.
  @doc ~S"""
    Sets the MATCH pattern into the query.  May take a string or a
    hash.

      iex> %Query{} |> Query.match("(x:Disease)") |> to_string
      "MATCH (x:Disease)"

      iex> %Query{} |> Query.match(x: Vertex.new("Medicine", %{dose: 42})) |> to_string
      "MATCH (x:Medicine {dose: 42})"

      iex> %Query{} |> Query.match(x: %{id: 42}) |> to_string
      "MATCH (x {id: 42})"

      iex> %Query{} |> Query.match(x: %{id: 42}, y: %{id: 69}) |> to_string
      "MATCH (x {id: 42}), (y {id: 69})"
  """
  def match(query=%Query{}, pattern) when is_bitstring(pattern) do
    %{query | match: pattern }
  end
  def match(query=%Query{}, hash) when is_map(hash) or is_list(hash) do
    pattern = Enum.map(hash, fn({k, v}) -> Cypher.to_cypher(v, k) end)
              |> Enum.join(", ")
    match(query, pattern)
  end

  @doc ~S"""
    Works as match/2, but will mix with MERGE keyword.  Note that Cypher
    permits MATCH and MERGE to be used together in some contructs.

      # iex> %Query{} |> Query.merge(x: Vertex.cast(Medicine, %{name: "foo"})) |> to_string
      "MERGE (x:Disease { name: 'foo' })"
  """
  def merge(query=%Query{}, pattern) when is_bitstring(pattern) do
    %{query | merge: pattern}
  end
  def merge(query=%Query{}, hash) when is_map(hash) or is_list(hash) do
    pattern = Enum.map(hash, fn{k, v} -> Cypher.to_cypher(v, k) end)
              |> Enum.join(", ")
    merge(query, pattern)
  end

  @doc ~S"""
    Sets the CREATE clause in the query.  Only supports strings for now.

      iex> %Query{} |> Query.create("(x:Disease { id: 42 })") |> to_string
      "CREATE (x:Disease { id: 42 })"
  """
  def create(query=%Query{}, pattern) when is_bitstring(pattern) do
    %{query | create: pattern}
  end

  # If you set the query to a string or nil, just accept it directly
  @doc ~S"""
    Sets the WHERE clause on the query.

    Can accept a string, nil (to clear any previous clause), or a Map or
    Keyword list of key/values that are ANDed together.  ONLY supports
    equality checks for the moment.

      iex> %Query{} |> Query.where("x = y") |> to_string
      "WHERE x = y"

      iex> %Query{} |> Query.where(x: "y", foo: "bar") |> to_string
      "WHERE (x = 'y') AND (foo = 'bar')"

      iex> %Query{} |> Query.where(%{x: "y", foo: "bar"}) |> to_string
      "WHERE (foo = 'bar') AND (x = 'y')"

    Note the order is different between a Keyword list and a Map.
  """
  def where(query=%Query{}, clause) when is_bitstring(clause) or is_nil(clause) do
    %{query | where: clause}
  end
  def where(query=%Query{}, hash) when is_map(hash) or is_list(hash) do
    clause = 
      Enum.map(hash, fn(x) -> "#{hd(Tuple.to_list(x))} = #{Tuple.to_list(x)|>List.last|>Cypher.escaped_quote}" end)
      |> Enum.join(") AND (")
    where(query, "(" <> clause <> ")")
  end

  @doc ~S"""
    Assigns the SET clause in the Cypher query.

    ## Examples

    Example of manually setting the clause directly...
      iex> %Query{} |> Query.set("x.name = 'Foo Cancer'") |> to_string
      "SET x.name = 'Foo Cancer'"

    Example of passing a Map of Maps (top-level keys are the matched
    entities, the map value is the key/value maps to update)
      iex> %Query{} |> Query.set(x: %{name: "Foo Cancer"}) |> to_string
      "SET x += {name: 'Foo Cancer'}"

    If you want to unset a property, send nil as the value
      iex> %Query{} |> Query.set(x: %{name: nil}) |> to_string
      "SET x += {name: NULL}"

  """
  def set(query=%Query{}, clause) when is_bitstring(clause) or is_nil(clause) do
    %{query | set: clause, delete: nil}
  end
  def set(query=%Query{}, hash) when is_map(hash) do
    set(query, Map.to_list(hash))
  end
  def set(query=%Query{}, kwlist) when is_list(kwlist) do
    clauses = Keyword.take(kwlist, [:on_create, :on_match])
    case clauses do
      [] -> set(query, Enum.map(kwlist, &set_one/1) |> Enum.join(", "))
      clauses -> set_on_clauses(query, clauses)
    end
  end
  defp set_on_clauses(query=%Query{}, clauses) do
    %{query | set: Enum.map(clauses, fn({x,y}) ->
      {x, Enum.map(y, &set_one/1) |> Enum.join(", ")}
    end) }
  end
  defp set_one({x, y}) do
    "#{to_string x} += #{Cypher.set_values(y)}"
  end

  def delete(query=%Query{}, vars) when is_list(vars) do
    %{query | set: nil, delete: vars}
  end
  def delete(query=%Query{}, var) do
    delete(query, [var])
  end

  # Set the return hash -- should be variable name => type (or nil)
  # This can be used later to convert the resulting rows to objects of the
  # appropriate type.
  @doc ~S"""
    Sets the values to be returned as keys mapped to types; set to true
    (boolean) to convert to %Vertex{} structs (note that the labels will
    not be filled in, they would have to be requested separately), or
    set to nil if no conversion should be done at all.

    Currently the values are not yet used (but can be used to cast the
    result to the appropriate struct).

    If passed a list, will use each element as a return key, but no type
    conversion will be done on the result.

    If passed a string, splits on commas and uses each part as a return
    key, again with no type conversion.

      iex> %Query{} |> Query.returning("x,y") |> to_string
      "RETURN x, y"

      iex> %Query{} |> Query.returning(["x", "y"]) |> to_string
      "RETURN x, y"

      iex> %Query{} |> Query.returning(%{x: Medicine, y: Treatment}) |> to_string
      "RETURN x, y"

  """
  def returning(query=%Query{}, kwlist) when is_list(kwlist) do
    clause = case Keyword.keyword?(kwlist) do
               true -> kwlist
               _ -> Enum.map(kwlist, fn x -> {x, nil} end)
             end
    %{query | return: clause}
  end
  def returning(query=%Query{}, hash) when is_map(hash) do
    returning(query, Map.to_list(hash))
  end
  def returning(query=%Query{}, string) when is_bitstring(string) do
    # Split string on commas, then call again as a list...
    parts = String.split(string, ",") |> Enum.map(&(String.strip(&1)))
    returning(query, parts)
  end
  def returning(query=%Query{}, atom) when is_atom(atom) do
    returning(query, to_string(atom))
  end

  # Order clause only accepts string or nil.
  def order(query=%Query{}, clause) when is_bitstring(clause) or is_nil(clause) do
    %{query | order: clause}
  end

  # Limiter only accepts integers or nil
  def limit(query=%Query{}, lim) when is_integer(lim) or is_nil(lim) do
    %{query | limit: lim}
  end

end

defimpl String.Chars, for: Callisto.Query do
  def to_string(q) do
    [match(q.match),
     merge(q.merge),
     create(q.create),
     where(q.where),
     set(q.set),
     delete(q.delete),
     return(q.return),
     order(q.order),
     limit(q.limit)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp match(nil), do: nil
  defp match(clause), do: "MATCH #{clause}"
  defp merge(nil), do: nil
  defp merge(clause), do: "MERGE #{clause}"
  defp create(nil), do: nil
  defp create(clause), do: "CREATE #{clause}"
  defp where(nil), do: nil
  defp where(clause), do: "WHERE #{clause}"
  defp set(nil), do: nil
  defp set(clause) when is_list(clause) do
    Enum.map(clause, fn({x,y}) ->
      {(Atom.to_string(x) |> String.upcase |> String.replace("_", " ")), y}
    end)
    |> Enum.map(fn({x,y}) -> 
      Enum.join([x,y], " SET ")
    end)
    |> Enum.join(" ")
  end
  defp set(clause), do: "SET #{clause}"
  defp delete(nil), do: nil
  defp delete(array), do: "DETACH DELETE #{Enum.join(array, ",")}"
  defp order(nil), do: nil
  defp order(clause), do: "ORDER BY #{clause}"
  defp limit(nil), do: nil
  defp limit(num), do: "LIMIT #{num}"

  defp return(nil), do: nil
  defp return(string) when is_bitstring(string) do
    "RETURN #{string}"
  end
  defp return(hash) do
    # Only care about the keys, which we join with commas.
    "RETURN #{Keyword.keys(hash) |> Enum.join(", ") }"
  end
end

