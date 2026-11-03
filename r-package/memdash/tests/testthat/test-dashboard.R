test_that("new_card produces a valid card definition", {
  c <- new_card()
  expect_true(nzchar(c$id))
  expect_true(c$type %in% CARD_TYPES)
  expect_equal(c$layout, "auto")
  expect_equal(c$width, "half")
  expect_type(c$scatter, "list")
})

test_that("dashboard JSON round-trips through save/load", {
  cards <- default_cards()
  f <- tempfile(fileext = ".json")
  on.exit(unlink(f))
  save_dashboard(cards, f, name = "test")
  d <- load_dashboard(f)
  expect_equal(d$name, "test")
  expect_equal(length(d$cards), length(cards))
  expect_equal(vapply(d$cards, function(c) c$id, character(1)),
               vapply(cards, function(c) c$id, character(1)))
  expect_equal(d$cards[[4]]$type, "scatter")
  expect_equal(d$cards[[4]]$scatter$colour, "colour")
  expect_equal(d$cards[[3]]$layout, "auto")
})

test_that("load_dashboard validates and fills defaults for legacy JSON", {
  f <- tempfile(fileext = ".json")
  on.exit(unlink(f))
  writeLines('{"cards":[{"id":"a","title":"t","type":"table","cypher":"RETURN 1"}]}', f)
  d <- load_dashboard(f)
  expect_equal(d$cards[[1]]$width, "half")
  expect_equal(d$cards[[1]]$layout, "auto")
  expect_equal(d$cards[[1]]$scatter, list())
  expect_equal(d$cards[[1]]$refresh, 0)
})

test_that("load_dashboard rejects non-dashboard JSON", {
  f <- tempfile(fileext = ".json")
  on.exit(unlink(f))
  writeLines('{"foo": 1}', f)
  expect_error(load_dashboard(f), "missing 'cards'")
})

test_that("parameter text helpers round-trip", {
  p <- list(limit = "25", name = "Ada Lovelace")
  expect_equal(text_to_params(params_to_text(p)), p)
  expect_equal(text_to_params(""), list())
})

test_that("memgraph_query errors cleanly when not connected", {
  memgraph_disconnect()
  expect_error(memgraph_query("RETURN 1"), "Not connected")
})

test_that("normalize_width maps legacy half/full and clamps to 1-12", {
  expect_equal(normalize_width("half"), 6L)
  expect_equal(normalize_width("full"), 12L)
  expect_equal(normalize_width(6), 6L)
  expect_equal(normalize_width(0), 1L)
  expect_equal(normalize_width(99), 12L)
  expect_equal(normalize_width("bogus"), 6L)
  expect_equal(normalize_width(NULL), 6L)
})

test_that("new_card accepts legacy width strings and numeric spans", {
  expect_equal(new_card(width = "full")$width, 12L)
  expect_equal(new_card(width = "half")$width, 6L)
  expect_equal(new_card(width = 4)$width, 4L)
  expect_equal(new_card(width = 20)$width, 12L)
})

test_that("legacy dashboard JSON with half/full widths loads as 6/12", {
  f <- tempfile(fileext = ".json")
  on.exit(unlink(f))
  writeLines('{"cards":[{"id":"a","title":"t","type":"table","cypher":"RETURN 1","width":"full"},{"id":"b","title":"u","type":"table","cypher":"RETURN 2","width":"half"}]}', f)
  d <- load_dashboard(f)
  expect_equal(d$cards[[1]]$width, 12L)
  expect_equal(d$cards[[2]]$width, 6L)
  expect_equal(dashboard_to_json(d$cards)$cards[[1]]$width, 12)
})
