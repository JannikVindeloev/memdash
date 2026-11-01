#' Build an igraph from memdash query records
#'
#' Uses \code{\link[=records_to_graph]{records_to_graph()}} and returns an
#' \code{igraph} graph with a \code{label} vertex attribute.
#' @export
records_to_igraph <- function(records) {
  g <- records_to_graph(records)
  if (!length(g$nodes)) {
    return(igraph::make_empty_graph(n = 0, directed = TRUE))
  }
  ids <- vapply(g$nodes, function(n) n$id, character(1))
  labels <- vapply(g$nodes, function(n) n$label, character(1))
  groups <- vapply(g$nodes, function(n) n$group, character(1))
  edges <- if (length(g$edges)) {
    data.frame(from = vapply(g$edges, function(e) e$from, character(1)),
               to = vapply(g$edges, function(e) e$to, character(1)),
               rel = vapply(g$edges, function(e) e$label, character(1)),
               stringsAsFactors = FALSE)
  } else {
    data.frame(from = character(0), to = character(0), rel = character(0), stringsAsFactors = FALSE)
  }
  ig <- igraph::graph_from_data_frame(edges, directed = TRUE, vertices = data.frame(id = ids, stringsAsFactors = FALSE))
  igraph::V(ig)$label <- labels[igraph::V(ig)$name]
  igraph::V(ig)$group <- groups[igraph::V(ig)$name]
  ig
}

#' Compute fixed 2D coordinates from a tidygraph layout algorithm
#'
#' Builds a \code{tbl_graph} from the records and runs
#' \code{tidygraph::create_layout(tg, layout = "igraph", algorithm = algorithm)},
#' returning coordinates scaled to a visNetwork canvas. These are the same
#' layout algorithms ggraph uses, so a visNetwork graph card can be rendered
#' with fixed ggraph/tidygraph positions.
#'
#' @param records \code{records} element of a \code{\link[=memgraph_query]{memgraph_query()}} result.
#' @param algorithm A tidygraph/igraph layout algorithm: \code{"fr"}, \code{"kk"},
#'   \code{"drl"}, \code{"graphopt"}, \code{"mds"}, \code{"circle"}, \code{"grid"},
#'   \code{"star"}, \code{"sugiyama"}.
#' @return An \code{n x 2} numeric matrix with \code{rownames} = node ids,
#'   columns \code{x}/\code{y} scaled to the visNetwork canvas.
#' @export
tidygraph_layout_coords <- function(records, algorithm = "fr") {
  tg <- records_to_tidygraph(records)
  if (tidygraph::gsize(tg) == 0 || tidygraph::gorder(tg) == 0) {
    return(matrix(numeric(0), ncol = 2, dimnames = list(NULL, c("x", "y"))))
  }
  lay <- tidygraph::create_layout(tg, layout = "igraph", algorithm = algorithm)
  nodes_tbl <- tidygraph::activate(lay, "nodes")
  coords <- scale_to(as.matrix(data.frame(x = nodes_tbl$x, y = nodes_tbl$y)), 600, 400)
  rownames(coords) <- as.character(nodes_tbl$name)
  coords
}

#' Compute 2D coordinates for an igraph with a named igraph layout
#'
#' @param ig An \code{igraph} graph.
#' @param layout One of the igraph layout keys in \code{GRAPH_LAYOUTS}
#'   (\code{"fr"}, \code{"kk"}, \code{"drl"}, \code{"graphopt"}, \code{"mds"},
#'   \code{"circle"}, \code{"grid"}, \code{"star"}, \code{"sugiyama"}).
#' @return An \code{n x 2} numeric matrix of x/y coordinates per vertex.
#' @export
igraph_layout_coords <- function(ig, layout) {
  if (igraph::vcount(ig) == 0) return(matrix(numeric(0), ncol = 2))
  coords <- switch(layout,
    fr = igraph::layout_with_fr(ig),
    kk = igraph::layout_with_kk(ig),
    drl = igraph::layout_with_drl(ig),
    graphopt = igraph::layout_with_graphopt(ig),
    mds = igraph::layout_with_mds(ig),
    circle = igraph::layout_in_circle(ig),
    grid = igraph::layout_on_grid(ig),
    star = igraph::layout_as_star(ig),
    sugiyama = igraph::layout_with_sugiyama(ig)$layout,
    igraph::layout_with_fr(ig)
  )
  coords <- as.matrix(coords[, 1:2, drop = FALSE])
  scale_to(coords, 600, 400)
}

scale_to <- function(m, w, h) {
  if (nrow(m) == 0) return(m)
  rng <- function(v) {
    r <- range(v, na.rm = TRUE)
    if (diff(r) < 1e-9) return(rep(0.5, length(v)))
    (v - r[1]) / diff(r)
  }
  m[, 1] <- rng(m[, 1]) * (w - 80) + 40
  m[, 2] <- (1 - rng(m[, 2])) * (h - 80) + 40
  m
}

#' Build a tidygraph from memdash query records (for ggraph rendering)
#' @export
records_to_tidygraph <- function(records) {
  ig <- records_to_igraph(records)
  tidygraph::as_tbl_graph(ig)
}

#' Render a graph card as a static ggraph plot
#' @export
ggraph_from_records <- function(records, layout = "fr") {
  tg <- records_to_tidygraph(records)
  if (tidygraph::gsize(tg) == 0) {
    return(ggplot2::ggplot() + ggplot2::annotate("text", 0, 0, label = "no graph data") + ggplot2::theme_void())
  }
  lay <- switch(layout,
    kk = tidygraph::create_layout(tg, layout = "igraph", algorithm = "kk"),
    drl = tidygraph::create_layout(tg, layout = "igraph", algorithm = "drl"),
    graphopt = tidygraph::create_layout(tg, layout = "igraph", algorithm = "graphopt"),
    mds = tidygraph::create_layout(tg, layout = "igraph", algorithm = "mds"),
    circle = tidygraph::create_layout(tg, layout = "igraph", algorithm = "circle"),
    grid = tidygraph::create_layout(tg, layout = "igraph", algorithm = "grid"),
    star = tidygraph::create_layout(tg, layout = "igraph", algorithm = "star"),
    sugiyama = tidygraph::create_layout(tg, layout = "igraph", algorithm = "sugiyama"),
    tidygraph::create_layout(tg, layout = "igraph", algorithm = "fr")
  )
  ggraph::ggraph(lay) +
    ggraph::geom_edge_link(ggplot2::aes(label = .data$rel), edge_alpha = 0.4,
                           arrow = ggplot2::arrow(length = ggplot2::unit(2, "mm")),
                           end_cap = ggraph::circle(4, "mm")) +
    ggraph::geom_node_point(ggplot2::aes(color = .data$group), size = 5) +
    ggraph::geom_node_text(ggplot2::aes(label = .data$label), repel = TRUE, size = 3) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "right")
}
