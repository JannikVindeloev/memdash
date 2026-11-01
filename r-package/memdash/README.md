# memdash (R package)

A Shiny dashboard for [Memgraph](https://memgraph.com), inspired by
[NeoDash](https://github.com/neo4j-contrib/neodash). It connects over **Bolt**
using the official Python [`neo4j`](https://pypi.org/project/neo4j/) driver
through **reticulate** — Memgraph speaks Bolt + openCypher, so no server-side
changes are needed.

## Install & run

```r
# 1. Python driver (once, in the reticulate Python env):
reticulate::py_install("neo4j")

# 2. Install the package (from r-package/memdash):
devtools::install("r-package/memdash")

# 3. Start Memgraph, e.g.:  docker run -p 7687:7687 memgraph/memgraph

# 4. Launch the dashboard:
memdash::run_memdash()
# then open the app, set Bolt URI to bolt://localhost:7687, press Connect,
# then "Load demo data" and "Run all".
```

## Using it in code (no Shiny)

```r
memdash::memgraph_connect("bolt://localhost:7687")
memdash::memdash_seed_demo()
res <- memdash::memgraph_query("MATCH (n)-[r]->(m) RETURN n, r, m LIMIT 50")
memdash::records_to_df(res$records, res$fields)   # data.frame for tables/charts
memdash::records_to_graph(res$records)            # nodes/edges for visNetwork
memdash::memgraph_query("MATCH (p:Person) RETURN p.name AS name LIMIT $limit",
                       params = list(limit = "10"))
memdash::memgraph_disconnect()
```

## Card types

`metric`, `table` (DT), `graph` (visNetwork), `bar` / `line` / `pie` (plotly),
`text` (Markdown), `json`. See `default_cards()` for example Cypher per type.

## Notes

- Requires R with `shiny`, `bslib`, `reticulate`, `jsonlite`, `DT`, `visNetwork`,
  `plotly`, `markdown` (all in `DESCRIPTION`) and a Python env with `neo4j` installed.
- If your Memgraph requires TLS, pass a `bolt+s://` / `neo4j+s://` URI.

## Documentation site

Hand-written `man/` pages cover every exported function, and a `pkgdown` config
(`_pkgdown.yml`) plus a `get-started` vignette are included:

```r
pkgdown::build_site("r-package/memdash")
```
