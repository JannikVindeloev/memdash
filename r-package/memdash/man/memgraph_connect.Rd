\name{memgraph_connect}
\alias{memgraph_connect}
\title{Connect to Memgraph through reticulate and the Python neo4j driver}
\usage{
memgraph_connect(uri = "bolt://localhost:7687", username = "", password = "", database = "memgraph")
}
\arguments{
\item{uri}{Bolt URI, default \code{bolt://localhost:7687}.}
\item{username}{Optional username (Memgraph default has no auth).}
\item{password}{Optional password.}
\item{database}{Optional database name (Memgraph default is \code{memgraph}).}
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
memgraph_connect("bolt://localhost:7687")
memgraph_connected()
memgraph_disconnect()
}
}
