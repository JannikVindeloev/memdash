\name{new_card}
\alias{new_card}
\title{Create a new dashboard card definition}
\usage{
new_card(id = NULL, title = "New card", type = c("table", CARD_TYPES),
  cypher = "MATCH (n) RETURN count(n) AS nodes", params = list(),
  refresh = 0, width = 6,
  layout = c("auto", "fr", "kk", "drl", "graphopt", "mds", "circle", "grid",
    "star", "sugiyama", "ggraph"),
  scatter = list(x = "", y = "", colour = "", shape = "", size = "", text = ""))
}
\arguments{
\item{id}{Card id (generated when \code{NULL}). Must be unique per dashboard.}
\item{title}{Card title shown in the header.}
\item{type}{One of \code{"metric"}, \code{"table"}, \code{"graph"}, \code{"scatter"},
\code{"bar"}, \code{"line"}, \code{"pie"}, \code{"text"}, \code{"json"}.}
\item{cypher}{openCypher query. \code{$param} placeholders are filled from \code{params}.}
\item{params}{Named list of parameter values, e.g. \code{list(limit = "25")}.}
\item{refresh}{Auto-refresh interval in seconds (\code{0} = off).}
\item{width}{Column span on a 12-column grid, integer \code{1}–\code{12}
(legacy \code{"half"}/\code{"full"} accepted, mapped to \code{6}/\code{12}).}
\item{layout}{Graph layout for \code{type = "graph"} cards: \code{"auto"}
(visNetwork forceAtlas2), a tidygraph layout name rendered as fixed positions, or
\code{"ggraph"} for a static tidygraph/ggraph plot. See \link{graph_layouts}.}
\item{scatter}{Named list mapping scatter-card columns to aesthetics:
\code{list(x, y, colour, shape, size, text)}; blank = auto (first/second column)
or none.}
}
\value{
A card definition (list).
}
\description{
Card definitions are the building blocks of a dashboard: they are edited in
\code{\link[=memdash_app]{memdash_app()}}, serialized with
\code{\link[=save_dashboard]{save_dashboard()}} and reloaded with
\code{\link[=load_dashboard]{load_dashboard()}}.
}
