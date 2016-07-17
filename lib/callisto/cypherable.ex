defprotocol Callisto.Cypherable do
  def to_cypher(vertex)
end

defimpl Callisto.Cypherable, for: Callisto.Vertex do
  def to_cypher(vertex, vertex_name \\ "vertex")
  def to_cypher(vertex, vertex_name), do: _to_cypher(vertex, vertex_name)

  defp _to_cypher(vertex, vertex_name) do
    labels = vertex.labels
    props = vertex.props
    element_name = vertex_name
    labels_suffix = _labels_suffix(labels)
    props_str = _props_str(props)
    cypher_str = "(" <> element_name <> labels_suffix <> " " <> props_str <> ")"
    {:ok, cypher_str}
  end

  defp _labels_suffix([]) do
    nil
  end

  defp _labels_suffix(labels) do
    ":" <> Enum.join(labels, ":")
  end

  defp _props_str(props) do
    props_string = Enum.map_join(props, ", ", fn({key, value}) ->
      if is_binary(value) do
        "#{key}: \"#{value}\""
      else
        "#{key}: #{value}"
      end
    end)
    "{#{props_string}}"
  end

  defp _return_str(element_name) do
    "RETURN labels(#{element_name}), #{element_name}"
  end
end

defimpl Callisto.Cypherable, for: Callisto.Edge do
  def to_cypher(edge, edge_name \\ "edge")
  def to_cypher(edge, edge_name), do: _to_cypher(edge, edge_name)

  defp _to_cypher(edge, edge_name) do
    from_vertex = edge.from
    to_vertex = edge.to

    # from_vertex_cypher = Callisto.Cypherable.to_cypher(from_vertex, "from_vertex")
    # to_vertex_cypher = Callisto.Cypherable.to_cypher(to_vertex, "to_vertex")

    cypher_str = "test test"
    {:ok, cypher_str}
  end
end
