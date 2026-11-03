\name{memdash-package}
\alias{memdash-package}
\alias{memdash}
\docType{package}
\title{memdash: Shiny dashboard for Memgraph}
\description{
Connects to Memgraph over Bolt using the Python \code{neo4j} driver via
\code{reticulate}, runs openCypher, and renders the results as dashboard
cards (table, graph, bar/line/pie chart, metric, text, JSON).
}
\details{
\code{\link[=memgraph_connect]{memgraph_connect()}} opens the Bolt connection,
\code{\link[=memgraph_query]{memgraph_query()}} runs Cypher, and
\code{\link[=run_memdash]{run_memdash()}} launches the Shiny dashboard.
}
\keyword{internal}
