# memdash 0.1.0

* Initial release.
* Bolt connection to Memgraph via reticulate + the official Python `neo4j`
  driver (`memgraph_connect()`), defaulting to tenant database `stxp4rd` for
  Memgraph Enterprise multi-tenancy.
* Cypher query API: `memgraph_query()` with `$param` substitution,
  `records_to_df()`, `records_to_graph()`, `memdash_seed_demo()`.
* Shiny dashboard builder (`memdash_app()` / `run_memdash()`): add/edit/delete
  cards, per-card Run and auto-refresh, in-card error display.
* Card types: metric, table (DT), graph, scatter (plotly x/y/colour/shape/
  size/text), bar/line/pie (plotly), text (Markdown), JSON.
* Graph layouts: visNetwork forceAtlas2 (`auto`), fixed tidygraph/igraph
  layouts rendered in visNetwork (`fr`, `kk`, `drl`, `graphopt`, `mds`,
  `circle`, `grid`, `star`, `sugiyama`), or static `ggraph`.
* Dashboard persistence as portable JSON (`save_dashboard()` /
  `load_dashboard()`) and `read_only` viewing mode.
