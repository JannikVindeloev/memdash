\name{memdash_seed_demo}
\alias{memdash_seed_demo}
\title{Seed demo data (same graph as the web UI)}
\usage{
memdash_seed_demo()
}
\value{
Invisible character string describing what was created.
}
\description{
Deletes all nodes and creates 4 \code{:Person} nodes, 3 \code{:Language}/
\code{:Database} nodes with relationships, and 24 \code{:Metric} rows.
}
\examples{
\dontrun{
memgraph_connect()
memdash_seed_demo()
}
}
