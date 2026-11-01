\name{graph_layouts}
\alias{records_to_igraph}
\alias{igraph_layout_coords}
\alias{records_to_tidygraph}
\alias{ggraph_from_records}
\title{igraph / tidygraph layouts for graph cards}
\usage{
records_to_igraph(records)

igraph_layout_coords(ig, layout)

records_to_tidygraph(records)

ggraph_from_records(records, layout = "fr")
}
\arguments{
\item{records}{\code{records} element of a \code{\link[=memgraph_query]{memgraph_query()}} result.}
\item{ig}{An \code{igraph} graph, e.g. from \code{records_to_igraph()}.}
\item{layout}{One of \code{"fr"}, \code{"kk"}, \code{"drl"}, \code{"graphopt"},
\code{"mds"}, \code{"circle"}, \code{"grid"}, \code{"star"}, \code{"sugiyama"}.}
}
\value{
\code{records_to_igraph()} returns an \code{igraph} graph with \code{label} and
\code{group} vertex attributes. \code{igraph_layout_coords()} returns an
\code{n x 2} numeric matrix of scaled x/y coordinates. \code{records_to_tidygraph()}
returns a \code{tbl_graph}. \code{ggraph_from_records()} returns a \code{ggplot}.
}
\description{
Graph cards in \code{\link[=memdash_app]{memdash_app()}} support several layouts
via the card's \code{layout} field: \code{"auto"} uses visNetwork's interactive
forceAtlas2 physics; igraph layout names (\code{"fr"}, \code{"kk"}, \code{"drl"},
\code{"graphopt"}, \code{"mds"}, \code{"circle"}, \code{"grid"}, \code{"star"},
\code{"sugiyama"}) compute fixed coordinates with igraph and render as a static
visNetwork with physics disabled; \code{"ggraph"} renders a static
tidygraph/ggraph plot.
}
\examples{
\dontrun{
memgraph_connect()
res <- memgraph_query("MATCH (n)-[r]->(m) RETURN n, r, m LIMIT 100")
ig <- records_to_igraph(res$records)
igraph_layout_coords(ig, "kk")
ggraph_from_records(res$records, "fr")
}
}
