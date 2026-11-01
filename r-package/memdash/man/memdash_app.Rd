\name{memdash_app}
\alias{memdash_app}
\alias{run_memdash}
\title{Build or launch the memdash Shiny app}
\usage{
memdash_app(cards = default_cards(), uri = "bolt://localhost:7687")

run_memdash(...)
}
\arguments{
\item{cards}{Card definitions, see \code{\link[=default_cards]{default_cards()}}.}
\item{uri}{Default Bolt URI shown in the connection dialog.}
\item{...}{Passed to \code{\link[=memdash_app]{memdash_app()}}.}
}
\value{
\code{memdash_app()} returns a \code{shiny.appobj}; \code{run_memdash()}
launches it via \code{shiny::runApp()}.
}
\description{
The Shiny UI has a connection bar (Bolt URI, credentials, Connect, Load demo
data, Run all, refresh interval) and renders each card as a metric, DT table,
visNetwork graph, plotly bar/line/pie chart, Markdown text or raw JSON.
}
\examples{
\dontrun{
run_memdash()
}
}
