defmodule Callisto.GraphDB.Queryable do
  alias Callisto.{Edge, Query, Vertex}

  def query(adapter, cypher, parser \\ nil) do
    do_query(adapter, cypher, parser)
  end
  defp do_query(adapter, cypher, parser)
       when is_bitstring(cypher) and is_nil(parser) do
    adapter.query(cypher)
  end
  defp do_query(adapter, cypher, parser)
      when is_bitstring(cypher) and is_function(parser) do
    case do_query(adapter, cypher, nil) do
      {:ok, result} -> {:ok, parser.(result) }
      result -> result
    end
  end
  defp do_query(adapter, cypher=%Query{}, parser) do
    do_query(adapter, to_string(cypher), fn(r) -> 
      result = Callisto.GraphDB.handle_return(r, cypher)
      (parser||&(&1)).(result)
    end)
  end

  def query!(adapter, cypher, parser \\ nil) do
    {:ok, response} = query(adapter, cypher, parser)
    response
  end

  def count(adapter, matcher) do
    cypher = %Query{}
             |> Query.match(matcher)
             |> Query.returning("count(x)")
    do_query(adapter, cypher, &(hd(&1)["count(x)"]))
  end

  def exists?(adapter, matcher) do
    cypher = %Query{}
             |> Query.match(matcher)
             |> Query.returning(:x)
             |> Query.limit(1)
    {:ok, c} = query(adapter, cypher)
    Enum.count(c) > 0
  end

  def get(adapter, kind=Vertex, labels, props) do
    query = %Query{}
            |> Query.match(x: kind.cast(labels, props))
            |> Query.returning(x: kind, "labels(x)": true)
    query(adapter, query,
          fn(rows) ->
            Enum.map(rows, fn(r) -> kind.cast(r["labels(x)"], r["x"]) end)
          end )
  end
  def get(adapter, kind=Edge, labels, props) do
    query = %Query{}
            |> Query.match(x: kind.cast(labels, props))
            |> Query.returning(x: kind, "type(x)": true)
    query(adapter, query,
          fn(rows) ->
            Enum.map(rows, fn(r) -> kind.cast(r["type(x)"], r["x"]) end)
          end )
  end
  def get!(adapter, kind, labels, props) do
    with {:ok, rows} <- get(adapter, kind, labels, props),
         do: rows
  end
  

end
