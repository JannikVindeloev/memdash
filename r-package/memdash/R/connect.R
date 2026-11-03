.memdash_state <- new.env(parent = emptyenv())
.memdash_state$driver <- NULL
.memdash_state$config <- NULL
.memdash_state$to_js <- NULL
.memdash_state$database <- NULL

.py_to_js_helper <- paste(
  "import datetime",
  "from neo4j.graph import Node, Relationship, Path",
  "",
  "def _to_js(v):",
  "    if v is None:",
  "        return None",
  "    if isinstance(v, Node):",
  "        nid = v.element_id if hasattr(v, 'element_id') else str(v.id)",
  "        return {'__type': 'node', '__id': nid, '__labels': sorted(v.labels),",
  "                'properties': {k: _to_js(x) for k, x in v.items()}}",
  "    if isinstance(v, Relationship):",
  "        rid = v.element_id if hasattr(v, 'element_id') else str(v.id)",
  "        start = v.start_node.element_id if getattr(v, 'start_node', None) is not None else str(v.start)",
  "        end = v.end_node.element_id if getattr(v, 'end_node', None) is not None else str(v.end)",
  "        return {'__type': 'relationship', '__id': rid, '__relType': v.type,",
  "                '__start': start, '__end': end,",
  "                'properties': {k: _to_js(x) for k, x in v.items()}}",
  "    if isinstance(v, Path):",
  "        return {'__type': 'path', 'nodes': [_to_js(n) for n in v.nodes],",
  "                'relationships': [_to_js(r) for r in v.relationships]}",
  "    if isinstance(v, (list, tuple)):",
  "        return [_to_js(x) for x in v]",
  "    if isinstance(v, dict):",
  "        return {k: _to_js(x) for k, x in v.items()}",
  "    if isinstance(v, (datetime.datetime, datetime.date, datetime.time, datetime.timedelta)):",
  "        return str(v)",
  "    if isinstance(v, (int, float, str, bool)):",
  "        return v",
  "    try:",
  "        from neo4j.time import DateTime, Date, Time, Duration",
  "        from neo4j.spatial import Point",
  "        if isinstance(v, (DateTime, Date, Time, Duration, Point)):",
  "            return str(v)",
  "    except Exception:",
  "        pass",
  "    return str(v)",
  "",
  "to_js = _to_js",
  sep = "\n"
)

#' Connect to Memgraph through reticulate and the Python neo4j driver
#'
#' Requires a Python environment with the \code{neo4j} package installed, e.g.
#' \code{reticulate::py_install("neo4j")}. Memgraph speaks Bolt + openCypher,
#' so the official Neo4j Python driver works unmodified.
#'
#' @param uri Bolt URI, default \code{bolt://localhost:7687}.
#' @param username Optional username (Memgraph default has no auth).
#' @param password Optional password.
#' @param database Tenant database name. For Memgraph Enterprise multi-tenancy
#'   this selects the tenant; defaults to \code{stxp4rd}.
#' @return Invisible \code{TRUE} on success; throws an error otherwise.
#' @export
memgraph_connect <- function(uri = "bolt://localhost:7687",
                             username = "",
                             password = "",
                             database = "stxp4rd") {
  neo4j <- tryCatch(
    reticulate::import("neo4j"),
    error = function(e) stop(
      "Python package 'neo4j' is required. Install it with: ",
      "reticulate::py_install('neo4j')  (original error: ", conditionMessage(e), ")",
      call. = FALSE
    )
  )
  auth <- if (nzchar(username) || nzchar(password)) neo4j$auth$basic(username, password) else NULL
  driver <- if (is.null(auth)) {
    neo4j$GraphDatabase$driver(uri)
  } else {
    neo4j$GraphDatabase$driver(uri, auth = auth)
  }
  driver$verify_connectivity()
  .memdash_state$driver <- driver
  .memdash_state$to_js <- reticulate::py_run_string(.py_to_js_helper)$to_js
  .memdash_state$config <- list(uri = uri, username = username, database = database)
  .memdash_state$database <- database
  invisible(TRUE)
}

#' Is there an active Memgraph connection?
#' @export
memgraph_connected <- function() !is.null(.memdash_state$driver)

#' Close the Memgraph connection
#' @export
memgraph_disconnect <- function() {
  if (!is.null(.memdash_state$driver)) {
    try(.memdash_state$driver$close(), silent = TRUE)
  }
  .memdash_state$driver <- NULL
  .memdash_state$config <- NULL
  .memdash_state$to_js <- NULL
  .memdash_state$database <- NULL
  invisible(TRUE)
}

#' Active connection config (uri, username, database)
#' @export
memgraph_config <- function() .memdash_state$config
