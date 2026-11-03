synth_records <- function() {
  list(
    list(
      n = list(`__type` = "node", `__id` = "1", `__labels` = c("Person"),
               properties = list(name = "Ada")),
      r = list(`__type` = "relationship", `__id` = "10", `__relType` = "KNOWS",
               `__start` = "1", `__end` = "2", properties = list()),
      m = list(`__type` = "node", `__id` = "2", `__labels` = c("Person"),
               properties = list(name = "Grace"))
    )
  )
}

test_that("records_to_graph extracts nodes and edges", {
  g <- records_to_graph(synth_records())
  expect_length(g$nodes, 2)
  expect_length(g$edges, 1)
  expect_equal(g$nodes[[1]]$label, "Ada")
  expect_equal(g$edges[[1]]$from, "1")
  expect_equal(g$edges[[1]]$to, "2")
  expect_equal(g$edges[[1]]$label, "KNOWS")
})

test_that("records_to_igraph builds an igraph with label/group attrs", {
  ig <- records_to_igraph(synth_records())
  expect_equal(igraph::vcount(ig), 2)
  expect_equal(igraph::ecount(ig), 1)
  expect_equal(sort(igraph::V(ig)$label), c("Ada", "Grace"))
  expect_true(all(igraph::V(ig)$group == "Person"))
})

test_that("tidygraph_layout_coords returns scaled coords keyed by node id", {
  coords <- tidygraph_layout_coords(synth_records(), "fr")
  expect_equal(ncol(coords), 2)
  expect_setequal(rownames(coords), c("1", "2"))
  expect_true(all(coords[, 1] >= 40 & coords[, 1] <= 600))
  expect_true(all(coords[, 2] >= 40 & coords[, 2] <= 400))
})

test_that("igraph_layout_coords handles each supported layout", {
  ig <- records_to_igraph(synth_records())
  for (lay in c("fr", "kk", "drl", "graphopt", "mds", "circle", "grid", "star", "sugiyama")) {
    coords <- igraph_layout_coords(ig, lay)
    expect_equal(nrow(coords), 2, info = lay)
    expect_equal(ncol(coords), 2, info = lay)
  }
})

test_that("ggraph_from_records returns a ggplot", {
  p <- ggraph_from_records(synth_records(), "fr")
  expect_s3_class(p, "ggplot")
})

test_that("records_to_df flattens values and handles empty input", {
  df <- records_to_df(list(list(a = 1, b = "x", g = list(`__type` = "node")), list(a = 2, b = "y", g = NULL)),
                      c("a", "b", "g"))
  expect_equal(nrow(df), 2)
  expect_equal(df$a, c("1", "2"))
  expect_true(grepl("__type", df$g[1]))
  empty <- records_to_df(list(), c("a", "b"))
  expect_equal(nrow(empty), 0)
  expect_equal(ncol(empty), 2)
})
