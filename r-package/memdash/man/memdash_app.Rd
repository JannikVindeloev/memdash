\name{memdash_app}
\alias{memdash_app}
\alias{run_memdash}
\title{Build or launch the memdash Shiny dashboard builder}
\usage{
memdash_app(cards = default_cards(), uri = "bolt://localhost:7687",
  read_only = FALSE, dashboard_file = NULL)

run_memdash(...)
}
\arguments{
\item{cards}{Card definitions, see \code{\link[=default_cards]{default_cards}()},
\code{\link[=new_card]{new_card}()}, or \code{\link[=load_dashboard]{load_dashboard}()}.}
\item{uri}{Default Bolt URI shown in the connection dialog.}
\item{read_only}{When \code{TRUE}, add/edit/delete controls are hidden and card
definitions cannot change — a viewing mode. Connect, Run all, per-card Run and
auto-refresh still work. App-level only; the JSON file itself stays editable text.}
\item{dashboard_file}{Optional path to a dashboard JSON file; cards load from it
and the app starts read-only.}
\item{...}{Passed to \code{memdash_app()}.}
}
\value{
\code{memdash_app()} returns a \code{shiny.appobj}; \code{run_memdash()}
launches it via \code{shiny::runApp()}.
}
\description{
The builder UI has a connection bar (Bolt URI, credentials, Connect, Load demo
data), dashboard controls (Add card, Save dashboard JSON, Load JSON, Run all,
global refresh), and a responsive card grid. Each card has a Run button, a gear
button opening an edit modal (title, visualization type, Cypher, $parameters,
per-card refresh, width), and renders as metric, DT table, visNetwork graph,
plotly bar/line/pie chart, Markdown text or raw JSON. Errors are shown inside
the card.
}
\examples{
\dontrun{
run_memdash()                                  # build from default cards
run_memdash(read_only = TRUE)                  # view-only mode
run_memdash(dashboard_file = "saved.json")     # view a saved dashboard, read-only
memdash_app(cards = load_dashboard("saved.json")$cards)  # editable copy
}
}
