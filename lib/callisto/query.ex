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
            return: nil,
            piped_queries: []

  def new do
    %Query{}
  end

  # Accept the match criteria directly.  Only strings supported.
  @doc ~S"""
    Sets the MATCH pattern into the query.  May take a string or a
    hash.

      iex> %Query{} |> Query.match("(x:Disease)") |> to_string
      "MATCH (x:Disease)"

      iex> %Query{} |> Query.match(x: Vertex.cast("Medicine", %{dose: 42})) |> to_string
      "MATCH (x:Medicine {dose: 42})"

      iex> %Query{} |> Query.match(x: %{id: 42}) |> to_string
      "MATCH (x {id: 42})"

      iex> %Query{} |> Query.match(x: %{id: 42}, y: %{id: 69}) |> to_string
      "MATCH (x {id: 42}), (y {id: 69})"
  """
  def match(pattern), do: match(%Query{}, pattern)
  def match(query=%Query{}, pattern) when is_binary(pattern) do
    %Query{match: pattern, piped_queries: append_query(query)}
  end
  def match(query=%Query{}, hash) when is_map(hash) or is_list(hash) do
    pattern = Enum.map(hash, fn({k, v}) -> Cypher.to_cypher(v, k) end)
              |> Enum.join(", ")
    match(query, pattern)
  end

  @doc ~S"""
    Works as match/2, but will mix with MERGE keyword.  Note that Cypher
    permits MATCH and MERGE to be used together in some contructs.

    iex> %Query{} |> Query.merge(x: Vertex.cast("Foo", %{name: "foo"})) |> to_string
    "MERGE (x:Foo {name: 'foo'})"

    iex> %Query{} |> Query.merge("foo") |> to_string
    "MERGE foo"

    iex> %Query{} |> Query.merge(x: Vertex.cast("Foo", %{name: "zoo"}), y: Vertex.cast("Baz", %{name: "bar"})) |> to_string
    "MERGE (x:Foo {name: 'zoo'})
    MERGE (y:Baz {name: 'bar'})"
  """
  def merge(pattern), do: merge(%Query{}, pattern)
  def merge(query=%Query{}, pattern) when is_binary(pattern) do
    %Query{merge: pattern, piped_queries: append_query(query)}
  end
  def merge(query=%Query{}, hash) when is_map(hash) do
    pattern = Enum.map(hash, fn{k, v} -> Cypher.to_cypher(v, k) end)
              |> Enum.join(", ")
    merge(query, pattern)
  end
  def merge(query=%Query{}, list) when is_list(list) do
    pattern = Enum.map(list, fn{k, v} -> "MERGE "<>Cypher.to_cypher(v, k) end)
              |> Enum.join("\n")
    merge(query, pattern)
  end

  @doc ~S"""
    Sets the CREATE clause in the query.  Only supports strings for now.

      iex> %Query{} |> Query.create("(x:Disease { id: 42 })") |> to_string
      "CREATE (x:Disease { id: 42 })"
  """
  def create(pattern), do: create(%Query{}, pattern)
  def create(query=%Query{}, pattern) when is_binary(pattern) do
    %Query{create: pattern, piped_queries: append_query(query)}
  end
  def create(query=%Query{}, vert=%Vertex{}) do
    pattern = Cypher.to_cypher(vert)
    create(query, pattern)
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
  def where(clause), do: where(%Query{}, clause)
  def where(query=%Query{}, clause) when is_binary(clause) or is_nil(clause) do
    %Query{where: clause, piped_queries: append_query(query)}
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
  def set(clause), do: set(%Query{}, clause)
  def set(query=%Query{}, clause) when is_binary(clause) or is_nil(clause) do
    %Query{set: clause, piped_queries: append_query(query)}
  end
  def set(query=%Query{}, hash) when is_map(hash) do
    set(query, Map.to_list(hash))
  end
  def set(query=%Query{}, kwlist) when is_list(kwlist) do
    clauses = Keyword.take(kwlist, [:on_create, :on_match])
    case clauses do
      [] -> set(query, Enum.map(kwlist, &set_one/1) |> Enum.join(", "))
      clauses -> %Query{set: set_on_multiple(clauses), piped_queries: append_query(query)}
    end
  end
  defp set_on_multiple(clauses) do
    Enum.map(clauses, fn({x,y}) ->
      {x, Enum.map(y, &set_one/1) |> Enum.join(", ")}
    end)
  end
  defp set_one({x, y}) do
    "#{to_string x} += #{Cypher.set_values(y)}"
  end

  @doc ~S"""
    Assigns the DELETE clause in the Cypher query.  Pass an array of elements
    to DELETE -- if you use the keyword detach: to identify the list, the
    elements will be detached instead.

    ## Examples

    Example of manually setting the clause directly...
      iex> %Query{} |> Query.delete("x") |> to_string
      "DELETE x"

    Example of passing a Map of Maps (top-level keys are the matched
    entities, the map value is the key/value maps to update)
      iex> %Query{} |> Query.delete(["x", "y"])|> to_string
      "DELETE x,y"

    Examples of detaching
      iex> %Query{} |> Query.delete(detach: "x")|> to_string
      "DETACH DELETE x"
      iex> %Query{} |> Query.delete(detach: ["x", "y"])|> to_string
      "DETACH DELETE x,y"


  """
  def delete(v), do: delete(%Query{}, v)
  def delete(query=%Query{}, detach: v) when is_list(v) do
    do_delete(query, %{detach: v})
  end
  def delete(query=%Query{}, detach: v), do: delete(query, detach: [v])
  def delete(query=%Query{}, v) when is_list(v) != true, do: delete(query, [v])
  def delete(query=%Query{}, v), do: do_delete(query, v)
  defp do_delete(query=%Query{}, v) do
    %Query{delete: v, piped_queries: append_query(query)}
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
  def returning(clause), do: returning(%Query{}, clause)
  def returning(query=%Query{}, kwlist) when is_list(kwlist) do
    clause = case Keyword.keyword?(kwlist) do
               true -> kwlist
               _ -> Enum.map(kwlist, fn x -> {x, nil} end)
             end
    %Query{return: clause, piped_queries: append_query(query)}
  end
  def returning(query=%Query{}, hash) when is_map(hash) do
    returning(query, Map.to_list(hash))
  end
  def returning(query=%Query{}, string) when is_binary(string) do
    # Split string on commas, then call again as a list...
    parts = String.split(string, ",") |> Enum.map(&(String.strip(&1)))
    returning(query, parts)
  end
  def returning(query=%Query{}, atom) when is_atom(atom) do
    returning(query, to_string(atom))
  end

  # Order clause only accepts string or nil.
  def order(clause), do: order(%Query{}, clause)
  def order(query=%Query{}, clause) when is_binary(clause) or is_nil(clause) do
    %Query{order: clause, piped_queries: append_query(query)}
  end

  # Limiter only accepts integers or nil
  def limit(lim), do: limit(%Query{}, lim)
  def limit(query=%Query{}, lim) when is_integer(lim) or is_nil(lim) do
    %Query{limit: lim, piped_queries: append_query(query)}
  end

  # Load piped queries into an attribute.
  defp append_query(query) do
    List.insert_at(query.piped_queries, -1, query)
  end
end

defimpl String.Chars, for: Callisto.Query do
  def to_string(q) do
    parse_chained_queries(q) <> do_to_string(q)
  end

  defp do_to_string(q) do
    [
      match(q.match),
      merge(q.merge),
      create(q.create),
      where(q.where),
      set(q.set),
      delete(q.delete),
      return(q.return),
      order(q.order),
      limit(q.limit),
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp parse_chained_queries(q) do
    cond do
      Enum.count(q.piped_queries) > 1 ->
        clause = q.piped_queries
          |> List.delete_at(0)
          |> Enum.map(&do_to_string/1)
          |> Enum.join("\n")
        clause <> "\n"
      true ->
        ""
    end
  end

  defp match(nil), do: nil
  defp match(clause), do: "MATCH #{clause}"
  defp merge(nil), do: nil
  defp merge("MERGE "<>clause) do
    "MERGE #{clause}"
  end
  defp merge(clause) do
    "MERGE #{clause}"
  end
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
  defp delete(array) when is_list(array), do: "DELETE #{Enum.join(array, ",")}"
  defp delete(%{detach: array}), do: "DETACH #{delete(array)}"
  defp order(nil), do: nil
  defp order(clause), do: "ORDER BY #{clause}"
  defp limit(nil), do: nil
  defp limit(num), do: "LIMIT #{num}"

  defp return(nil), do: nil
  defp return(string) when is_binary(string) do
    "RETURN #{string}"
  end
  defp return(hash) do
    # Only care about the keys, which we join with commas.
    "RETURN #{Keyword.keys(hash) |> Enum.join(", ") }"
  end
end
