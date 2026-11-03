\name{save_dashboard}
\alias{save_dashboard}
\alias{load_dashboard}
\alias{dashboard_to_json}
\title{Save and load dashboards as JSON files}
\usage{
save_dashboard(cards, file, name = "memdash dashboard")

load_dashboard(file)

dashboard_to_json(cards, name = "memdash dashboard")
}
\arguments{
\item{cards}{List of card definitions, e.g. from \code{\link[=default_cards]{default_cards}()}
or \code{\link[=new_card]{new_card}()}.}
\item{file}{Path of the JSON file to write (\code{save_dashboard}) or read (\code{load_dashboard}).}
\item{name}{Dashboard name stored in the file.}
}
\value{
\code{save_dashboard()} returns invisible \code{file}. \code{load_dashboard()}
returns a validated list with \code{name} and \code{cards}. \code{dashboard_to_json()}
returns the plain list (schemaVersion 1) before serialization.
}
\description{
Dashboards persist as portable JSON (same schema as the web app). Anyone with
the package can rebuild a saved dashboard:

\code{memdash_app(cards = load_dashboard("my.json")$cards)} — or in read-only
viewing mode: \code{memdash_app(dashboard_file = "my.json")}.

Note the JSON file is plain text, so \code{read_only} in the app is a UI-level
flag, not filesystem-level access control.
}
\examples{
\dontrun{
save_dashboard(default_cards(), "demo.json")
d <- load_dashboard("demo.json")
memdash_app(cards = d$cards)                 # editable copy
memdash_app(dashboard_file = "demo.json")    # read-only viewer
}
}
