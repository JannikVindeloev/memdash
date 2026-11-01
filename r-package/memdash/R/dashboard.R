CARD_TYPES <- c("metric", "table", "graph", "scatter", "bar", "line", "pie", "text", "json")

SCATTER_AES <- c("x", "y", "colour", "shape", "size", "text")

GRAPH_LAYOUTS <- c(
  "auto" = "auto (visNetwork forceAtlas2)",
  "fr" = "igraph: Fruchterman-Reingold",
  "kk" = "igraph: Kamada-Kawai",
  "drl" = "igraph: DrL",
  "graphopt" = "igraph: graphopt",
  "mds" = "igraph: MDS",
  "circle" = "igraph: circle",
  "grid" = "igraph: grid",
  "star" = "igraph: star",
  "sugiyama" = "igraph: Sugiyama (dendrogram)",
  "ggraph" = "tidygraph/ggraph (static)"
)

`%||%` <- function(a, b) if (is.null(a)) b else a

new_card_id <- function() {
  paste0("c", format(as.integer(Sys.time() * 1e6), scientific = FALSE),
         paste(sample(c(letters, 0:9), 4), collapse = ""))
}

#' Create a new dashboard card definition
#'
#' @param id Card id (generated when \code{NULL}). Must be unique per dashboard.
#' @param title Card title shown in the header.
#' @param type One of \code{"metric"}, \code{"table"}, \code{"graph"},
#'   \code{"bar"}, \code{"line"}, \code{"pie"}, \code{"text"}, \code{"json"}.
#' @param cypher openCypher query. \code{$param} placeholders are filled from \code{params}.
#' @param params Named list of parameter values, e.g. \code{list(limit = "25")}.
#' @param refresh Auto-refresh interval in seconds (\code{0} = off).
#' @param width Column span on a 12-column grid, integer \code{1}–\code{12}
#'   (legacy \code{"half"}/\code{"full"} values are accepted and mapped to
#'   \code{6}/\code{12}). This is how cards are resized in the app.
#' @param layout Graph layout for \code{type = "graph"} cards: \code{"auto"} for
#'   visNetwork's forceAtlas2, an igraph layout name (\code{"fr"}, \code{"kk"},
#'   \code{"drl"}, \code{"graphopt"}, \code{"mds"}, \code{"circle"}, \code{"grid"},
#'   \code{"star"}, \code{"sugiyama"}) computed with igraph and rendered as fixed
#'   positions in visNetwork, or \code{"ggraph"} for a static tidygraph/ggraph plot.
#' @return A card definition (list).
#' @export
new_card <- function(id = NULL, title = "New card",
                     type = c("table", CARD_TYPES),
                     cypher = "MATCH (n) RETURN count(n) AS nodes",
                     params = list(), refresh = 0,
                     width = 6,
                     layout = c("auto", names(GRAPH_LAYOUTS)),
                     scatter = list(x = "", y = "", colour = "", shape = "", size = "", text = "")) {
  list(
    id = id %||% new_card_id(),
    title = title,
    type = match.arg(type),
    cypher = cypher,
    params = params,
    refresh = refresh,
    width = normalize_width(width),
    layout = match.arg(layout),
    scatter = if (is.null(scatter)) list() else as.list(scatter)
  )
}

normalize_width <- function(w) {
  if (is.character(w)) {
    w <- switch(w, half = 6L, full = 12L, NA_integer_)
  }
  w <- suppressWarnings(as.integer(w))
  if (length(w) != 1 || is.na(w)) w <- 6L
  max(1L, min(12L, w))
}

#' Serialize cards to the memdash dashboard JSON structure
#' @param cards List of card definitions.
#' @param name Dashboard name.
#' @return A plain list ready for \code{jsonlite::toJSON()} (schemaVersion 1).
#' @export
dashboard_to_json <- function(cards, name = "memdash dashboard") {
  list(
    schemaVersion = 1,
    name = name,
    savedAt = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    cards = lapply(cards, function(c) list(
      id = c$id,
      title = c$title,
      type = c$type,
      cypher = c$cypher,
      params = if (is.null(c$params)) list() else c$params,
      refresh = c$refresh %||% 0,
      width = normalize_width(c$width),
      layout = c$layout %||% "auto",
      scatter = if (is.null(c$scatter)) list() else as.list(c$scatter)
    ))
  )
}

#' Save a dashboard (card list) to a JSON file
#'
#' The file can be reloaded with \code{\link{load_dashboard}()} by anyone using
#' the package, recreating the dashboard exactly. The schema matches the web
#' app's persisted format (schemaVersion 1).
#' @param cards List of card definitions.
#' @param file Path of the JSON file to write.
#' @param name Dashboard name stored in the file.
#' @return Invisible \code{file}.
#' @export
save_dashboard <- function(cards, file, name = "memdash dashboard") {
  writeLines(jsonlite::toJSON(dashboard_to_json(cards, name), auto_unbox = TRUE, pretty = TRUE), file)
  invisible(file)
}

#' Load a dashboard from a JSON file
#'
#' @param file Path of a JSON file written by \code{\link{save_dashboard}()}.
#' @return A list with \code{name} and \code{cards} (validated card definitions).
#' @export
load_dashboard <- function(file) {
  raw <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  validate_dashboard(raw)
}

validate_dashboard <- function(raw) {
  if (!is.list(raw) || is.null(raw$cards)) {
    stop("Not a memdash dashboard JSON: missing 'cards'.", call. = FALSE)
  }
  cards <- lapply(raw$cards, function(c) {
    if (is.null(c$id)) c$id <- new_card_id()
    if (is.null(c$title)) c$title <- "Untitled"
    if (is.null(c$type) || !(c$type %in% CARD_TYPES)) c$type <- "table"
    if (is.null(c$cypher)) c$cypher <- ""
    c$params <- if (is.null(c$params)) list() else as.list(c$params)
    if (is.null(c$refresh)) c$refresh <- 0
    c$width <- normalize_width(c$width)
    if (is.null(c$layout) || !(c$layout %in% names(GRAPH_LAYOUTS))) c$layout <- "auto"
    if (is.null(c$scatter)) c$scatter <- list()
    c
  })
  list(name = raw$name %||% "memdash dashboard", cards = cards)
}

params_to_text <- function(params) {
  if (!length(params)) return("")
  paste(vapply(names(params), function(n) paste0(n, "=", params[[n]]), character(1)), collapse = "\n")
}

text_to_params <- function(txt) {
  out <- list()
  if (is.null(txt) || !nzchar(trimws(txt))) return(out)
  for (line in strsplit(txt, "\n", fixed = TRUE)[[1]]) {
    i <- regexpr("=", line, fixed = TRUE)
    if (i > 1) out[[trimws(substr(line, 1, i - 1))]] <- trimws(substr(line, i + 1, nchar(line)))
  }
  out
}
