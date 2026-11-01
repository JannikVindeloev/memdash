#' Built-in example cards (same queries as the web UI)
#' @export
default_cards <- function() {
  list(
    new_card(id = "nodes", title = "Node count", type = "metric",
             cypher = "MATCH (n) RETURN count(n) AS nodes", width = "half"),
    new_card(id = "people", title = "People", type = "table",
             cypher = "MATCH (p:Person) RETURN p.name AS name, p.born AS born ORDER BY born", width = "half"),
    new_card(id = "graph", title = "Graph", type = "graph",
             cypher = "MATCH (n)-[r]->(m) RETURN n, r, m LIMIT 50", width = "full"),
    new_card(id = "requests", title = "Requests per hour", type = "bar",
             cypher = "MATCH (m:Metric) RETURN m.hour AS hour, m.requests AS requests ORDER BY hour", width = "half"),
    new_card(id = "latency", title = "Latency trend", type = "line",
             cypher = "MATCH (m:Metric) RETURN m.hour AS hour, m.latency AS latency ORDER BY hour", width = "half"),
    new_card(id = "scatter", title = "Requests vs latency", type = "scatter", width = "half",
             cypher = "MATCH (m:Metric) RETURN m.hour AS x, m.latency AS y, m.requests AS colour, m.hour AS text",
             scatter = list(x = "x", y = "y", colour = "colour", shape = "", size = "", text = "text")),
    new_card(id = "labels", title = "Nodes per label", type = "pie",
             cypher = "MATCH (n) RETURN labels(n)[0] AS label, count(*) AS n ORDER BY n DESC", width = "half"),
    new_card(id = "about", title = "About", type = "text",
             cypher = "RETURN '# memdash\n\nShiny dashboard for **Memgraph** via the Python neo4j driver (reticulate).' AS md", width = "half"),
    new_card(id = "raw", title = "Raw JSON", type = "json",
             cypher = "MATCH (p:Person) RETURN p LIMIT 5", width = "half")
  )
}
