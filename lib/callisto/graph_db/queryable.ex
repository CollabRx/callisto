defmodule Callisto.GraphDB.Queryable do
  alias Callisto.{Edge, Query, Triple, Vertex}

  def query(adapter, cypher, parser \\ nil) do
    do_query(adapter, cypher, parser)
  end
  # Straight up cypher string, no parser...
  defp do_query(adapter, cypher, parser)
       when is_bitstring(cypher) and is_nil(parser) do
    adapter.query(cypher)
  end
  # Straight up cypher, but with a parsing function
  defp do_query(adapter, cypher, parser)
      when is_bitstring(cypher) and is_function(parser) do
    case do_query(adapter, cypher, nil) do
      {:ok, result} -> {:ok, parser.(result) }
      result -> result
    end
  end
  # Cypher struct, possible parser.
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
    query(adapter, cypher, &(hd(&1)["count(x)"]))
  end
  def count!(adapter, matcher) do
    with {:ok, c} <- count(adapter, matcher),
         do: c
  end

  def exists?(adapter, matcher) do
    cypher = %Query{}
             |> Query.match(matcher)
             |> Query.returning(:x)
             |> Query.limit(1)
    {:ok, c} = query(adapter, cypher)
    Enum.count(c) > 0
  end

  def get(adapter, kind, labels, props) when is_list(props) do
    get(adapter, kind, labels, Map.new(props))
  end
  def get(adapter, kind=Vertex, labels, props) do
    query = %Query{}
            |> Query.match(x: kind.cast(labels, props))
            |> Query.returning(x: kind, "labels(x)": nil)
    query(adapter, query, &deref_all/1)
  end
  def get(adapter, kind=Edge, labels, props) do
    query = %Query{}
            |> Query.match(x: kind.cast(labels, props))
            |> Query.returning(x: kind, "type(x)": nil)
    query(adapter, query, &deref_all/1)
  end
  def get!(adapter, kind, labels, props) do
    with {:ok, rows} <- get(adapter, kind, labels, props),
         do: rows
  end

  def create(adapter, vertex=%Vertex{}) do
    cypher = %Query{}
             |> Query.create(vertex)
             |> Query.returning(x: Vertex, "labels(x)": nil)
    query(adapter, cypher, &deref_all/1)
  end

  def create(adapter, triple=%Triple{}) do
    cypher = %Query{}
             |> Query.match(from: triple.from, to: triple.to)
             |> Query.create("(from)-#{Edge.to_cypher(triple.edge,"r")}->(to)")
             |> Query.returning(from: Vertex, "labels(from)": nil,
                                r: Edge, "type(r)": nil,
                                to: Vertex, "labels(to)": nil)
    query(adapter, cypher, fn(rows) ->
      Enum.map(rows, fn(r) ->
        Triple.new(from: r["from"], edge: r["r"], to: r["to"])
      end)
    end)
  end

  def get_or_create(adapter, vertex=%Vertex{}) do
    cypher = %Query{}
             |> Query.merge(x: vertex)
             |> Query.returning(x: Vertex, "labels(x)": nil)
    query(adapter, cypher, &deref_all/1)
  end

  defp deref_all(rows, key \\ "x") do
    Enum.map(rows, &(&1[key]))
  end

  def delete(adapter, vertex=%Vertex{}, opts) do
    cypher = %Query{}
             |> Query.match(x: vertex)
             |> Query.delete(if(Keyword.get(opts, :detach),
                                do: [detach: :x],
                                else: :x))
    query(adapter, cypher)
  end
         
end
