# same functionality as Repo, but customized for graph, graph repo = grepo
# if there were an ecto plugin for neo4j this would exist, but since it doesn't,
# let's just do this for now.
defmodule Callisto.GraphDB do
  alias Callisto.{Edge, Query, Vertex}

  @moduledoc """
    Defines a graph DB (repository).

    When used, the graph DB expects `:otp_app` option, which should point to
    the OTP application that has the repository configuration.  For example,

      defmodule Graph do
        use Callisto.GraphDB, otp_app: :my_app
      end

    Could be configured with:

      config :my_app, Graph,
        adapter: Callisto.Adapters.Neo4j,
        url: "http://localhost:7474",
        basic_auth: [username: "neo4j", password: "password"]

    Most of the configuration is specific to the adapter, check the adapter
    source for details.
  """

  # NOTE:  I stole a ton of this from Ecto, and probably did it wrong in the
  #        process...  ...Paul
  defmacro __using__(options) do
    quote bind_quoted: [opts: options] do
      @behaviour Callisto.GraphDB

      @otp_app Keyword.fetch!(opts, :otp_app)
      @config Application.get_env(@otp_app, __MODULE__, [])
      @adapter (opts[:adapter] || @config[:adapter])

      unless @adapter do
        raise ArgumentError, "missing :adapter configuration in config #{inspect @otp_app}, #{inspect __MODULE__}"
      end

      def query(cypher, parser \\ nil) do
        Callisto.GraphDB.Queryable.query(@adapter, cypher, parser)
      end
        
      def query!(cypher, parser \\ nil) do
        Callisto.GraphDB.Queryable.query!(@adapter, cypher, parser)
      end

      def count(matcher) do
        Callisto.GraphDB.Queryable.count(@adapter, matcher)
      end
      def count!(matcher) do
        Callisto.GraphDB.Queryable.count!(@adapter, matcher)
      end
       

      def exists?(matcher) do
        Callisto.GraphDB.Queryable.exists?(@adapter, matcher)
      end

      def get(finder, labels, props \\ %{}) do
        Callisto.GraphDB.Queryable.get(@adapter, finder, labels, props)
      end

      def get!(finder, labels, props \\ %{}) do
        Callisto.GraphDB.Queryable.get!(@adapter, finder, labels, props)
      end

      def create(vertex=%Callisto.Vertex{}) do
        Callisto.GraphDB.Queryable.create(@adapter, vertex)
      end

      def create(triple=%Callisto.Triple{}) do
        Callisto.GraphDB.Queryable.create(@adapter, triple)
      end
      def create(from=%Callisto.Vertex{},
                 edge=%Callisto.Edge{},
                 to=%Callisto.Vertex{}) do
        create(Callisto.Triple.new(from: from, to: to, edge: edge))
      end

      def get_or_create(vertex=%Callisto.Vertex{}) do
        Callisto.GraphDB.Queryable.get_or_create(@adapter, vertex)
      end

      def delete(vertex=%Callisto.Vertex{}, opts \\ []) do
        Callisto.GraphDB.Queryable.delete(@adapter, vertex, opts)
      end

    end
  end

  @doc ~S"""
    Runs an arbitrary Cypher query against Neo4j.  Can take a straight string
    or an Callisto.Query structure (if the latter, will attempt to convert
    results to structs based on the :return key -- handle_return/2).

    Optional function argument will receive the array of results (if status
    is :ok); the return from the function will replace the return.  Useful
    for dereferencing a single key to return just a list of values -- or
    for popping the first off)

      # Example:  Return only the first row's data.
      {:ok, x} = Repo.query("MATCH (x) RETURN x", fn(r) -> hd(r)["x"] end)

      # Example: Return dereferenced list.
      %Query{match: "(v:Foo)"} |> Query.returning(v: MyApp.Foo)
      |> GraphDB.query(fn(row) -> Enum.map(row, &(&1["v"])) end)
  """
  @callback query(module, String.t | struct, fun | nil) :: tuple

  @doc ~S"""
    Runs an arbitrary Cypher query against Neo4j.  Can take a straight string
    or an Callisto.Query structure.  Returns only the response.
  """
  @callback query!(String.t | struct, fun | nil) :: list(map)

  @doc ~S"""
    Returns {:ok, count} of elements that match the <matcher> with the label
    <kind>

      iex> Repo.count("(x:Disease)")
      {:ok, 0}
      iex> Repo.count("(x:Claim)")
      {:ok, 1}
  """
  @callback count(String.t | struct) :: tuple
  @callback count!(String.t | struct) :: integer | tuple

  @doc ~S"""
    Returns true/false if there is at least one element that matches the
    parameters.

      iex> Repo.exists?("(x:Disease)")
      false
      iex> Repo.exists?("(x:Claim)")
      true
  """
  @callback exists?(String.t | struct) :: boolean

  @doc ~S"""
    Constructs query to return objects of type <type> (Vertex or Edge),
    with label(s) <labels>, and optionally properties or ID.  Returns
    tuple from query(), but on success, second element of tuple is a list
    of results cast into the appropriate structs (Vertex or Edge).

    The last argument, if provided, is expected to be a hash of property
    values to match against.  These values are completely ignored, though,
    if the hash has an :id key -- in that case, or if the last argument is
    a string or integer, the only property that will be searched against is
    the ID given.
  """
  @callback get(Vertex.t | Edge.t, list(String.t | module), any) :: tuple
  @callback get!(Vertex.t | Edge.t, list(String.t | module), any) :: list(struct)

  @doc ~S"""
    Creates the given object
    Given a Vertex, creates the vertex and returns the resulting Vertex.
    Given a Triple, creates the path and returns the Triple.
    Returns {:ok, [results]} on success.
  """
  @callback create(Vertex.t | Triple.t) :: tuple

  @doc ~S"""
    Expects arguments from (vertex), edge (edge), to (vertex).  Simply tosses
    in a Triple and then creates the edges.  See create()
    Returns {:ok, [triples]} on success.
  """
  @callback create(Vertex.t, Edge.t, Vertex.t) :: tuple

  @doc ~S"""
    Returns existing matching Vertex record; if none exist, one is created
    and returned.  Returns {:ok, [vertices]} on success.
  """
  @callback get_or_create(Vertex.t) :: tuple

  @doc ~S"""
    Deletes all vertices that match. Returns {:ok, []} on success (on success,
    the right side is always an empty list.)

    If detach: true is passed along, will delete the vertex and any remaining
    edges attached to it (by default, will not detach)

    Graph.delete(Vertex.new("Foo"), detach: true)
    Cypher: "MATCH (x:Foo) DETACH DELETE x"
  """
  @callback delete(Vertex.t, keyword) :: tuple

  # This takes a returned tuple from Neo4j and a Callisto.Query struct;
  # it looks at the Query's return key and attempts to convert the
  # returned data to the matching structs (if indicated).  If there's
  # no struct given for a key, it is unchanged.  Finally, returns
  # the tuple with the updated results.
  def handle_return(rows, %Query{return: returning}) 
       when is_list(returning) do
    Enum.map rows, fn(row) ->
      Enum.map(returning, fn({k, v}) ->
        key = to_string(k)
        cond do
          is_nil(v) -> {key, row[key]}
          v == true -> {key, Vertex.cast([], row[key])}
          v == Vertex -> {key, Vertex.cast(row["labels(#{key})"], row[key])}
          v == Edge -> {key, Edge.cast(row["type(#{key})"], row[key])}
          is_binary(v) -> {key, Vertex.cast(v, row[key])}
          is_atom(v) || is_list(v) -> {key, Vertex.cast(v, row[key])}
          true -> {key, row[key]}
        end
      end)
      |> Map.new
    end
  end
  # No return structure defined, just return what we got, likely nothing.
  def handle_return(rows, %Query{return: r}) when is_nil(r), do: rows

end
