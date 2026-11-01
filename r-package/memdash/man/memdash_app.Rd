\name{memdash_app}
\alias{memdash_app}
\alias{run_memdash}
\title{Build or launch the memdash Shiny dashboard builder}
\usage{
memdash_app(cards = default_cards(), uri = "bolt://localhost:7687",
  read_only = FALSE, dashboard_file = NULL, database = "stxp4rd")

run_memdash(...)
}
\arguments{
\item{cards}{Card definitions, see \code{\link[=default_cards]{default_cards}()},
\code{\link[=new_card]{new_card}()}, or \code{\link[=load_dashboard]{load_dashboard}()}.}
\item{uri}{Default Bolt URI shown in the connection dialog.}
\item{database}{Default tenant database shown in the connection dialog (Memgraph
Enterprise multi-tenancy; default \code{stxp4rd}).}
\item{read_only}{When \code{TRUE}, add/edit/delete controls are hidden and card
definitions cannot change — a viewing mode. Connect, Run all, per-card Run and
auto-refresh still work. App-level only; the JSON file itself stays editable text.}
\item{dashboard_file}{Optional path to a dashboard JSON file; cards load from it
and the app starts read-only.}
\item{...}{Passed to \code{memdash_app()}.}
}
\details{
Cards are laid out on a 12-column grid (\code{bslib::layout_column_wrap}); each
card's \code{width} is its column span, resized with a 1–12 slider in the edit
modal and persisted in the dashboard JSON. Legacy \code{"half"}/\code{"full"}
widths in older JSON files load as \code{6}/\code{12}.
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
per-card refresh, width slider = 1–12 column span for resizing, graph layout,
scatter aesthetics), and renders as
metric, DT table, visNetwork graph (auto/tidygraph-fixed/ggraph layouts),
plotly scatter (x, y, colour, shape, size, hover text) or bar/line/pie chart,
Markdown text or raw JSON. Errors are shown inside the card.
}
\examples{
\dontrun{
run_memdash()                                  # build from default cards
run_memdash(read_only = TRUE)                  # view-only mode
run_memdash(dashboard_file = "saved.json")     # view a saved dashboard, read-only
memdash_app(cards = load_dashboard("saved.json")$cards)  # editable copy
}
}
