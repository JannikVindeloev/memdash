# memdash

A shiny, NeoDash-style dashboard for [Memgraph](https://memgraph.com). Memgraph speaks the
Bolt protocol and openCypher, so memdash connects with the official `neo4j-driver` and runs
plain Cypher — no plugins or adaptations needed.

Inspired by [NeoDash](https://github.com/neo4j-contrib/neodash).

## Features

- **Connect screen** — Bolt URI, optional username/password/database (default `bolt://localhost:7687`)
- **Drag-and-drop card grid** (react-grid-layout, persisted to localStorage)
- **Cypher editor per card** with `$parameter` substitution and optional auto-refresh
- **Visualizations**: table, graph (canvas force layout with draggable nodes), bar / line / pie
  charts, single-value metric, Markdown text, raw JSON
- **Run all** button and **Load demo data** to seed an example graph + metrics

## Run

```bash
# 1. Start Memgraph (any way you like), e.g. with Docker:
docker run -p 7687:7687 -p 7444:7444 memgraph/memgraph

# 2. Install and start memdash:
npm install
npm run dev
# open http://localhost:5173, connect to bolt://localhost:7687
```

Build for production:

```bash
npm run build
npm run preview
```

## Example queries

```cypher
// Graph card
MATCH (n)-[r]->(m) RETURN n, r, m LIMIT 50

// Metric card
MATCH (n) RETURN count(n) AS nodes

// Bar chart card
MATCH (m:Metric) RETURN m.hour AS hour, m.requests AS requests ORDER BY hour

// Table card with a parameter ($limit in the query)
MATCH (p:Person) RETURN p.name AS name, p.born AS born LIMIT $limit
```

## Stack

React 18 + TypeScript + Vite, MUI, zustand (persisted state), react-grid-layout, recharts,
react-markdown, neo4j-driver (Bolt client for Memgraph).

## R / Shiny version

There is also an R package under [`r-package/memdash`](r-package/memdash) that connects to
Memgraph from R via **reticulate** + the Python `neo4j` driver (Bolt), with a Shiny UI
(`memdash::run_memdash()`) and a programmatic API (`memgraph_connect()`, `memgraph_query()`,
`records_to_df()`, `records_to_graph()`). See [r-package/memdash/README.md](r-package/memdash/README.md).
