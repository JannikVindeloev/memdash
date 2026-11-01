\name{memgraph_query}
\alias{memgraph_query}
\title{Run a Cypher query against Memgraph}
\usage{
memgraph_query(cypher, params = list())
}
\arguments{
\item{cypher}{openCypher query string. Use \code{$param} placeholders and pass
values in \code{params} (they are substituted as quoted literals).}
\item{params}{Named character list, e.g. \code{list(limit = "25")} for \code{$limit}.}
}
\value{
A list with elements \code{records} (list of named lists; graph values are
plain lists carrying \code{__type}/\code{__labels}/\code{__id} markers),
\code{fields} (character vector) and \code{summary} (list with \code{row_count}
and \code{duration_ms}).
}
\description{
Runs \code{cypher} on the active connection opened by
\code{\link[=memgraph_connect]{memgraph_connect()}}.
}
\examples{
\dontrun{
memgraph_connect()
res <- memgraph_query("MATCH (p:Person) RETURN p.name AS name LIMIT $limit",
                      params = list(limit = "10"))
res$fields
records_to_df(res$records, res$fields)
}
}
