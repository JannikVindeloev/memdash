py_to_r <- function(x) reticulate::py_to_r(x)

flatten_value <- function(v) {
  if (is.null(v)) return(NA_character_)
  if (is.list(v)) return(jsonlite::toJSON(v, auto_unbox = TRUE))
  as.character(v)
}

#' Run a Cypher query against Memgraph
#'
#' @param cypher openCypher query string. Use \code{$param} placeholders and pass
#'   values in \code{params} (they are substituted as quoted literals).
#' @param params Named character list, e.g. \code{list(limit = "25")} for \code{$limit}.
#' @return A list with elements \code{records} (list of named lists; graph values
#'   are plain lists carrying \code{__type}/\code{__labels}/\code{__id} markers),
#'   \code{fields} (character vector) and \code{summary} (list with
#'   \code{row_count} and \code{duration_ms}).
#' @export
memgraph_query <- function(cypher, params = list()) {
  if (!memgraph_connected()) stop("Not connected. Call memgraph_connect() first.", call. = FALSE)
  query <- cypher
  for (nm in names(params)) {
    escaped <- gsub("\\", "\\\\", as.character(params[[nm]]), fixed = TRUE)
    escaped <- gsub('"', '\\"', escaped, fixed = TRUE)
    query <- gsub(paste0("$", nm), paste0('"', escaped, '"'), query, fixed = TRUE)
  }
  to_js <- .memdash_state$to_js
  driver <- .memdash_state$driver
  db <- .memdash_state$database
  session <- if (!is.null(db) && nzchar(db)) driver$session(database = db) else driver$session()
  on.exit(try(session$close(), silent = TRUE), add = TRUE)
  t0 <- proc.time()[["elapsed"]]
  result <- session$run(query)
  fields <- as.character(py_to_r(result$keys()))
  recs_py <- result$data()
  n <- length(recs_py)
  records <- vector("list", n)
  for (i in seq_len(n)) {
    rec <- recs_py[[i]]
    keys <- as.character(py_to_r(rec$keys()))
    row <- vector("list", length(keys))
    names(row) <- keys
    for (k in keys) row[[k]] <- py_to_r(to_js(rec[[k]]))
    records[[i]] <- row
  }
  duration_ms <- round((proc.time()[["elapsed"]] - t0) * 1000)
  list(records = records, fields = fields,
       summary = list(row_count = n, duration_ms = duration_ms))
}

#' Convert query records to a data.frame for tables/charts
#'
#' Graph values (nodes/relationships) and nested structures are JSON-encoded.
#' @export
records_to_df <- function(records, fields) {
  if (length(records) == 0) {
    return(as.data.frame(setNames(replicate(length(fields), character(0), simplify = FALSE), fields),
                         stringsAsFactors = FALSE))
  }
  cols <- lapply(fields, function(f) vapply(records, function(r) flatten_value(r[[f]]), character(1)))
  as.data.frame(setNames(cols, fields), stringsAsFactors = FALSE)
}

#' Extract nodes and edges from query records for visNetwork
#'
#' Walks the records and collects the dicts carrying \code{__type} markers
#' produced by \code{\link{memgraph_query}}.
#' @export
records_to_graph <- function(records) {
  nodes <- list()
  edges <- list()
  seen_n <- character(0)
  seen_e <- character(0)
  visit <- function(v) {
    if (!is.list(v)) return(invisible(NULL))
    ty <- v[["__type"]]
    if (identical(ty, "node")) {
      id <- as.character(v[["__id"]])
      if (!(id %in% seen_n)) {
        seen_n <<- c(seen_n, id)
        props <- if (is.null(v$properties)) list() else v$properties
        caption <- id
        for (k in c("name", "title", "label", "id")) {
          if (!is.null(props[[k]])) { caption <- as.character(props[[k]]); break }
        }
        labels <- if (is.null(v[["__labels"]])) character(0) else unlist(v[["__labels"]])
        nodes[[length(nodes) + 1]] <<- list(
          id = id, label = caption, title = paste(labels, collapse = ":"),
          group = if (length(labels)) labels[[1]] else "Node",
          shape = "dot", properties = props
        )
      }
      return(invisible(NULL))
    }
    if (identical(ty, "relationship")) {
      id <- as.character(v[["__id"]])
      if (!(id %in% seen_e)) {
        seen_e <<- c(seen_e, id)
        edges[[length(edges) + 1]] <<- list(
          id = id, from = as.character(v[["__start"]]), to = as.character(v[["__end"]]),
          label = as.character(v[["__relType"]]), title = as.character(v[["__relType"]])
        )
      }
      return(invisible(NULL))
    }
    for (el in v) visit(el)
  }
  for (r in records) for (el in r) visit(el)
  list(nodes = nodes, edges = edges)
}

#' Seed demo data (same graph as the web UI)
#' @export
memdash_seed_demo <- function() {
  stmts <- c(
    "MATCH (n) DETACH DELETE n",
    paste(
      "CREATE (a:Person {name: 'Ada Lovelace', born: 1815}),",
      "(g:Person {name: 'Grace Hopper', born: 1906}),",
      "(m:Person {name: 'Alan Turing', born: 1912}),",
      "(k:Person {name: 'Katherine Johnson', born: 1918}),",
      "(lang1:Language {name: 'Cypher'}), (lang2:Language {name: 'Python'}),",
      "(db:Database {name: 'Memgraph'}),",
      "(a)-[:KNOWS {since: 1843}]->(g), (g)-[:WROTE]->(lang2), (a)-[:WROTE]->(lang1),",
      "(m)-[:KNOWS {since: 1936}]->(a),",
      "(k)-[:WORKED_ON]->(db), (m)-[:WORKED_ON]->(db), (g)-[:WORKED_ON]->(db)"
    ),
    paste(
      "UNWIND range(1, 24) AS h",
      "CREATE (:Metric {hour: h, requests: toInteger(200 + 180 * sin(h / 24 * 6.28) + rand() * 80),",
      "latency: toFloat(round(20 + rand() * 30))})"
    )
  )
  for (s in stmts) memgraph_query(s)
  invisible("Demo graph created: 4 Person nodes, 3 Language/Database nodes, 24 Metric rows.")
}
