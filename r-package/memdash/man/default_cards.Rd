\name{default_cards}
\alias{default_cards}
\title{Built-in example cards (same queries as the web UI)}
\usage{
default_cards()
}
\value{
A list of card definitions, each a list with \code{id}, \code{title},
\code{type} (one of \code{"metric"}, \code{"table"}, \code{"graph"},
\code{"bar"}, \code{"line"}, \code{"pie"}, \code{"text"}, \code{"json"})
and \code{cypher}.
}
\description{
Example Cypher per visualization type, used by
\code{\link[=memdash_app]{memdash_app()}} by default.
}
