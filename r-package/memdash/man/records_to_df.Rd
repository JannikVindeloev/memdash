\name{records_to_df}
\alias{records_to_df}
\alias{records_to_graph}
\title{Convert query records to data structures for tables, charts and graphs}
\usage{
records_to_df(records, fields)

records_to_graph(records)
}
\arguments{
\item{records}{\code{records} element of a \code{\link[=memgraph_query]{memgraph_query()}} result.}
\item{fields}{\code{fields} element of a \code{\link[=memgraph_query]{memgraph_query()}} result.}
}
\value{
\code{records_to_df()} returns a \code{data.frame} with one column per field;
graph values and nested structures are JSON-encoded. \code{records_to_graph()}
returns a list with \code{nodes} and \code{edges} lists suitable for
\code{visNetwork::visNetwork()}.
}
\description{
\code{records_to_df()} flattens records for tables/charts.
\code{records_to_graph()} walks the records and collects the dicts carrying
\code{__type} markers produced by \code{\link[=memgraph_query]{memgraph_query()}}.
}
\examples{
\dontrun{
memgraph_connect()
res <- memgraph_query("MATCH (n)-[r]->(m) RETURN n, r, m LIMIT 50")
g <- records_to_graph(res$records)
length(g$nodes); length(g$edges)
}
}
