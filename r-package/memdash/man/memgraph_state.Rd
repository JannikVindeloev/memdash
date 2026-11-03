\name{memgraph_connected}
\alias{memgraph_connected}
\alias{memgraph_disconnect}
\alias{memgraph_config}
\title{Inspect and close the active Memgraph connection}
\usage{
memgraph_connected()

memgraph_disconnect()

memgraph_config()
}
\value{
\code{memgraph_connected()} returns \code{TRUE}/\code{FALSE}.
\code{memgraph_disconnect()} closes the driver and returns invisible \code{TRUE}.
\code{memgraph_config()} returns a list with \code{uri}, \code{username}, \code{database},
or \code{NULL} when not connected.
}
\description{
\code{memgraph_connected()} reports whether a driver is active,
\code{memgraph_disconnect()} closes it, and \code{memgraph_config()} returns
the configuration used by \code{\link[=memgraph_connect]{memgraph_connect()}}.
}
