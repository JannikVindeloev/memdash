#' Built-in example cards (same queries as the web UI)
#' @export
default_cards <- function() {
  list(
    list(id = "nodes", title = "Node count", type = "metric",
         cypher = "MATCH (n) RETURN count(n) AS nodes"),
    list(id = "people", title = "People", type = "table",
         cypher = "MATCH (p:Person) RETURN p.name AS name, p.born AS born ORDER BY born"),
    list(id = "graph", title = "Graph", type = "graph",
         cypher = "MATCH (n)-[r]->(m) RETURN n, r, m LIMIT 50"),
    list(id = "requests", title = "Requests per hour", type = "bar",
         cypher = "MATCH (m:Metric) RETURN m.hour AS hour, m.requests AS requests ORDER BY hour"),
    list(id = "latency", title = "Latency trend", type = "line",
         cypher = "MATCH (m:Metric) RETURN m.hour AS hour, m.latency AS latency ORDER BY hour"),
    list(id = "labels", title = "Nodes per label", type = "pie",
         cypher = "MATCH (n) RETURN labels(n)[0] AS label, count(*) AS n ORDER BY n DESC"),
    list(id = "about", title = "About", type = "text",
         cypher = "RETURN '# memdash\n\nShiny dashboard for **Memgraph** via the Python neo4j driver (reticulate).' AS md"),
    list(id = "raw", title = "Raw JSON", type = "json",
         cypher = "MATCH (p:Person) RETURN p LIMIT 5")
  )
}
