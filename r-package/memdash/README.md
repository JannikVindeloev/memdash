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
# Memgraph Enterprise multi-tenancy: the tenant database defaults to
# "stxp4rd" (editable in the app's connection bar and in memgraph_connect()).
```

## Using it in code (no Shiny)

```r
memdash::memgraph_connect("bolt://localhost:7687", database = "stxp4rd")
memdash::memdash_seed_demo()
res <- memdash::memgraph_query("MATCH (n)-[r]->(m) RETURN n, r, m LIMIT 50")
memdash::records_to_df(res$records, res$fields)   # data.frame for tables/charts
memdash::records_to_graph(res$records)            # nodes/edges for visNetwork
memdash::memgraph_query("MATCH (p:Person) RETURN p.name AS name LIMIT $limit",
                       params = list(limit = "10"))
memdash::memgraph_disconnect()
```

## Card types

`metric`, `table` (DT), `graph`, `bar` / `line` / `pie` (plotly),
`text` (Markdown), `json`. See `default_cards()` for example Cypher per type.

Graph cards support multiple layouts via the card's `layout` field:
`auto` (interactive visNetwork forceAtlas2), or a tidygraph/igraph algorithm
(`fr`, `kk`, `drl`, `graphopt`, `mds`, `circle`, `grid`, `star`, `sugiyama`) whose
fixed coordinates — computed with `tidygraph::create_layout()`, the same
algorithms ggraph uses — are fed to visNetwork as static node positions
(physics off), or `ggraph` (static ggraph plot). Helpers: `records_to_igraph()`,
`igraph_layout_coords()`, `tidygraph_layout_coords()`,
`records_to_tidygraph()`, `ggraph_from_records()`.

## Building, saving and sharing dashboards

`run_memdash()` is a full builder: add/edit/delete cards (title, visualization
type, Cypher with `$params`, per-card auto-refresh, width), Run per card or
Run all, and save the whole dashboard as a portable JSON file:

```r
save_dashboard(cards, "my_dashboard.json")   # persist
d <- load_dashboard("my_dashboard.json")      # recreate anywhere
memdash_app(cards = d$cards)                 # editable copy
memdash_app(dashboard_file = "my_dashboard.json")  # read-only viewer
run_memdash(read_only = TRUE)                # view-only mode
```

`read_only = TRUE` hides all editing controls (viewers can still connect, run
and refresh). It is an app-level flag — the JSON file itself remains plain,
editable text.

## Notes

- Requires R with `shiny`, `bslib`, `reticulate`, `jsonlite`, `DT`, `visNetwork`,
  `plotly`, `markdown` (all in `DESCRIPTION`) and a Python env with `neo4j` installed.
- If your Memgraph requires TLS, pass a `bolt+s://` / `neo4j+s://` URI.
- Memgraph Enterprise multi-tenant setups: pass the tenant name as `database`
  (default `stxp4rd`); every query session is opened against that tenant.

## Documentation site

Hand-written `man/` pages cover every exported function, and a `pkgdown` config
(`_pkgdown.yml`) plus a `get-started` vignette are included:

```r
pkgdown::build_site("r-package/memdash")
```
