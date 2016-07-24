if Code.ensure_loaded?(Neo4j.Sips) do

  defmodule Callisto.Adapters.Neo4j do

    @doc false
    def child_spec(_repo, opts) do
      Neo4j.Sips.child_spec(opts)
    end

    def query(cypher) do
      Neo4j.Sips.query(Neo4j.Sips.conn, cypher)
    end
  end

end
