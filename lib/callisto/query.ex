defmodule Callisto.Query do
  def create(%Callisto.Vertex{} = vertex) do
    vertex_element_name = "vertex"
    {:ok, vertex_cypher_str} = Callisto.Cypherable.to_cypher(vertex)
    cypher_str = "CREATE " <> vertex_cypher_str <> " RETURN labels(#{vertex_element_name}), #{vertex_element_name}"
    {:ok, cypher_str}
  end

  def create(%Callisto.Edge{} = edge) do
    edge_element_name = "edge"
    from_vertex_element_name = "from_vertex"
    to_vertex_element_name = "to_vertex"

    {:ok, edge_cypher_str} = Callisto.Cypherable.to_cypher(edge)
    cypher_str = "CREATE " <> edge_cypher_str <> " RETURN labels(#{from_vertex_element_name}), #{from_vertex_element_name}, labels(#{to_vertex_element_name}), #{to_vertex_element_name}, type(#{edge_element_name}), #{edge_element_name}"
    {:ok, cypher_str}
  end
end
