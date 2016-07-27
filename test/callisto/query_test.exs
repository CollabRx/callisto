defmodule Callisto.QueryTest do
  use ExUnit.Case
  alias Callisto.{Query, Vertex}

  describe "match/1" do
    test "match with string" do
      query_str = Query.match("d:Disease") |> to_string
      assert query_str == "MATCH d:Disease"
    end
    test "match with empty map" do
      query_str = Query.match(d: Vertex.cast("Disease", %{})) |> to_string
      assert query_str == "MATCH (d:Disease)"
    end
    test "chained match with empty map" do
      query_str = Query.match(m: Vertex.cast("Medicine", %{})) |> Query.match(d: Vertex.cast("Disease", %{})) |> to_string
      assert query_str == "MATCH (m:Medicine)\nMATCH (d:Disease)"
    end
    test "match string with attributes" do
      query_str = Query.match("d:Disease {id: 123}") |> to_string
      assert query_str == "MATCH d:Disease {id: 123}"
    end
    test "match map with attributes" do
      query_str = Query.match(d: Vertex.cast("Disease", %{name: "Cold"})) |> to_string
      assert query_str == "MATCH (d:Disease {name: 'Cold'})"
    end
  end

  describe "match/2" do
    test "basic match" do
      query_str = %Query{} |> Query.match("d:Disease") |> to_string
      assert query_str == "MATCH d:Disease"
    end
    test "chained match" do
      query_str = %Query{} |> Query.match("d:Disease") |> Query.match("m:Medicine") |> to_string
      assert query_str == "MATCH d:Disease\nMATCH m:Medicine"
    end
    test "chained match with more elements" do
      query_str = %Query{} |> Query.match("d:Disease") |> Query.match("m:Medicine") |> Query.match("t:Treatment") |> to_string
      assert query_str == "MATCH d:Disease\nMATCH m:Medicine\nMATCH t:Treatment"
    end
  end

  describe "merge/1" do
    test "merge with string" do
      query_str = Query.merge("d:Disease") |> to_string
      assert query_str == "MERGE d:Disease"
    end
    test "merge with empty map" do
      query_str = Query.merge(d: Vertex.cast("Disease", %{})) |> to_string
      assert query_str == "MERGE (d:Disease)"
    end
    test "chained merge with empty map" do
      query_str = Query.merge(m: Vertex.cast("Medicine", %{})) |> Query.merge(d: Vertex.cast("Disease", %{})) |> to_string
      assert query_str == "MERGE (m:Medicine)\nMERGE (d:Disease)"
    end
    test "merge string with attributes" do
      query_str = Query.merge("d:Disease {id: 123}") |> to_string
      assert query_str == "MERGE d:Disease {id: 123}"
    end
    test "merge map with attributes" do
      query_str = Query.merge(d: Vertex.cast("Disease", %{name: "Cold"})) |> to_string
      assert query_str == "MERGE (d:Disease {name: 'Cold'})"
    end
  end

  describe "merge/2" do
    test "basic merge" do
      query_str = %Query{} |> Query.merge("d:Disease") |> to_string
      assert query_str == "MERGE d:Disease"
    end
    test "chained merge" do
      query_str = %Query{} |> Query.merge("d:Disease") |> Query.merge("m:Medicine") |> to_string
      assert query_str == "MERGE d:Disease\nMERGE m:Medicine"
    end
    test "chained merge with more elements" do
      query_str = %Query{} |> Query.merge("d:Disease") |> Query.merge("m:Medicine") |> Query.merge("t:Treatment") |> to_string
      assert query_str == "MERGE d:Disease\nMERGE m:Medicine\nMERGE t:Treatment"
    end
  end

  describe "create/1" do
    test "basic create" do
      query_str = Query.create("m:Medicine") |> to_string
      assert query_str == "CREATE m:Medicine"
    end
    test "chained create" do
      query_str = Query.create("m:Medicine") |> Query.create("t:Treatment") |> to_string
      assert query_str == "CREATE m:Medicine\nCREATE t:Treatment"
    end
    test "chained create with more elements" do
      query_str = Query.create("d:Disease") |> Query.create("m:Medicine") |> Query.create("t:Treatment") |> to_string
      assert query_str == "CREATE d:Disease\nCREATE m:Medicine\nCREATE t:Treatment"
    end
  end

  describe "where/1" do
    test "basic where" do
      query_str = Query.where("x = y") |> to_string
      assert query_str == "WHERE x = y"
    end
    test "where with keywords" do
      query_str = Query.where(x: "Xenon", y: "Yelp") |> to_string
      assert query_str == "WHERE (x = 'Xenon') AND (y = 'Yelp')"
    end
    test "where with more keywords" do
      query_str = Query.where(x: "Xenon", y: "Yelp", z: "Boson") |> to_string
      assert query_str == "WHERE (x = 'Xenon') AND (y = 'Yelp') AND (z = 'Boson')"
    end
    test "where with map" do
      query_str = Query.where(%{x: "Xenon", y: "Yelp"}) |> to_string
      assert query_str == "WHERE (x = 'Xenon') AND (y = 'Yelp')"
    end
    test "where with map with more keys" do
      query_str = Query.where(%{x: "Xenon", y: "Yelp", z: "Boson"}) |> to_string
      assert query_str == "WHERE (x = 'Xenon') AND (y = 'Yelp') AND (z = 'Boson')"
    end
    test "chained basic where" do
      query_str = Query.where("x = y") |> Query.where("z = y") |> to_string
      assert query_str == "WHERE x = y\nWHERE z = y"
    end
    test "chained basic where with more elements" do
      query_str = Query.where("x = y") |> Query.where("z = y") |> Query.where("j = z") |> to_string
      assert query_str == "WHERE x = y\nWHERE z = y\nWHERE j = z"
    end
  end

  describe "set/1" do
    test "basic set" do
      query_str = Query.set("c.name = 'Foo Cancer'") |> to_string
      assert query_str == "SET c.name = 'Foo Cancer'"
    end
    test "set with map" do
      query_str = Query.set(c: %{name: "Foo Cancer"}) |> to_string
      assert query_str == "SET c += {name: 'Foo Cancer'}"
    end
    test "set with keywords on create" do
      query_str = Query.set(on_create: [c: %{name: "Foo Cancer"}]) |> to_string
      assert query_str == "ON CREATE SET c += {name: 'Foo Cancer'}"
    end
    test "set with keywords on create multiple" do
      query_str = Query.set(on_create: [c: %{name: "Foo Cancer"}, b: %{name: "Boo Cancer"}]) |> to_string
      assert query_str == "ON CREATE SET c += {name: 'Foo Cancer'}, b += {name: 'Boo Cancer'}"
    end
    test "set with keywords on match" do
      query_str = Query.set(on_match: [c: %{name: "Foo Cancer"}]) |> to_string
      assert query_str == "ON MATCH SET c += {name: 'Foo Cancer'}"
    end
    test "set with keywords on match multiple" do
      query_str = Query.set(on_match: [c: %{name: "Foo Cancer"}, b: %{name: "Boo Cancer"}]) |> to_string
      assert query_str == "ON MATCH SET c += {name: 'Foo Cancer'}, b += {name: 'Boo Cancer'}"
    end
    test "set with keywords on match multiple for both types" do
      query_str = Query.set(on_match: [c: %{name: "Foo Cancer"}, b: %{name: "Boo Cancer"}], on_create: [c: %{created_by: "Person"}]) |> to_string
      assert query_str == "ON MATCH SET c += {name: 'Foo Cancer'}, b += {name: 'Boo Cancer'} ON CREATE SET c += {created_by: 'Person'}"
    end
    test "chained set" do
      query_str = Query.set(on_create: [c: %{name: "Foo Cancer"}]) |> Query.set(on_match: [b: %{name: "Boo Cancer"}]) |> to_string
      assert query_str == "ON CREATE SET c += {name: 'Foo Cancer'}\nON MATCH SET b += {name: 'Boo Cancer'}"
    end
  end

  describe "delete/1" do
    test "basic delete" do
      query_str = Query.delete("x") |> to_string
      assert query_str == "DELETE x"
    end
    test "detach" do
      query_str = Query.delete(detach: "x")|> to_string
      assert query_str == "DETACH DELETE x"
    end
    test "chained delete" do
      query_str = Query.delete("x") |> Query.delete("y") |> to_string
      assert query_str == "DELETE x\nDELETE y"
    end
  end

  describe "returning/1" do
    test "basic return" do
      query_str = Query.returning("x,y") |> to_string
      assert query_str == "RETURN x, y"
    end
    test "chained return with order" do
      query_str = Query.returning("x,y") |> Query.order("x.name") |> to_string
      assert query_str == "RETURN x, y\nORDER BY x.name"
    end
  end

  describe "order/1" do
    test "basic order" do
      query_str = Query.order("x.name") |> to_string
      assert query_str == "ORDER BY x.name"
    end
  end

  describe "limit/1" do
    test "basic limit" do
      query_str = Query.limit(5) |> to_string
      assert query_str == "LIMIT 5"
    end
  end

  describe "combo chained queries" do
    test "chained match and merge" do
      query_str = %Query{} |> Query.match("d:Disease") |> Query.merge("m:Medicine") |> Query.merge("t:Treatment") |> to_string
      assert query_str == "MATCH d:Disease\nMERGE m:Medicine\nMERGE t:Treatment"
    end
    test "chained merge and match" do
      query_str = %Query{} |> Query.merge("d:Disease") |> Query.match("m:Medicine") |> Query.match("t:Treatment") |> to_string
      assert query_str == "MERGE d:Disease\nMATCH m:Medicine\nMATCH t:Treatment"
    end
    test "chained match and create" do
      query_str = %Query{} |> Query.match("d:Disease") |> Query.create("m:Medicine") |> Query.create("t:Treatment") |> to_string
      assert query_str == "MATCH d:Disease\nCREATE m:Medicine\nCREATE t:Treatment"
    end
    test "chained merge and where" do
      query_str = Query.merge("d:Disease") |> Query.merge("m:Medicine") |> Query.where("m.name = 'Lemons'") |> to_string
      assert query_str == "MERGE d:Disease\nMERGE m:Medicine\nWHERE m.name = 'Lemons'"
    end
    test "merge with set" do
      query_str = Query.merge("m:Medicine") |> Query.set(on_create: [m: %{name: "Lemons"}]) |> to_string
      assert query_str == "MERGE m:Medicine\nON CREATE SET m += {name: 'Lemons'}"
    end
  end
end
