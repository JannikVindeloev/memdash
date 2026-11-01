\name{new_card}
\alias{new_card}
\title{Create a new dashboard card definition}
\usage{
new_card(id = NULL, title = "New card", type = c("table", CARD_TYPES),
  cypher = "MATCH (n) RETURN count(n) AS nodes", params = list(),
  refresh = 0, width = c("half", "full"))
}
\arguments{
\item{id}{Card id (generated when \code{NULL}). Must be unique per dashboard.}
\item{title}{Card title shown in the header.}
\item{type}{One of \code{"metric"}, \code{"table"}, \code{"graph"}, \code{"bar"},
\code{"line"}, \code{"pie"}, \code{"text"}, \code{"json"}.}
\item{cypher}{openCypher query. \code{$param} placeholders are filled from \code{params}.}
\item{params}{Named list of parameter values, e.g. \code{list(limit = "25")}.}
\item{refresh}{Auto-refresh interval in seconds (\code{0} = off).}
\item{width}{\code{"half"} or \code{"full"} column width.}
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
