\name{memgraph_connect}
\alias{memgraph_connect}
\title{Connect to Memgraph through reticulate and the Python neo4j driver}
\usage{
memgraph_connect(uri = "bolt://localhost:7687", username = "", password = "", database = "stxp4rd")
}
\arguments{
\item{uri}{Bolt URI, default \code{bolt://localhost:7687}.}
\item{username}{Optional username (Memgraph default has no auth).}
\item{password}{Optional password.}
\item{database}{Tenant database name. For Memgraph Enterprise multi-tenancy this
selects the tenant; defaults to \code{stxp4rd}.}
}
\value{
Invisible \code{TRUE} on success; throws an error otherwise.
}
\description{
Requires a Python environment with the \code{neo4j} package installed, e.g.
\code{reticulate::py_install("neo4j")}. Memgraph speaks Bolt + openCypher,
so the official Neo4j Python driver works unmodified.
}
\examples{
\dontrun{
reticulate::py_install("neo4j")
memgraph_connect("bolt://localhost:7687", database = "stxp4rd")
memgraph_connected()
memgraph_disconnect()
}
}
