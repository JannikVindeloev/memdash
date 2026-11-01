card_output_id <- function(id) paste0("card_", id)

render_card <- function(card, result) {
  if (is.null(result) || length(result$records) == 0 && is.null(result$error)) {
    return(tags$p(class = "text-secondary", "No data yet — press Run."))
  }
  if (!is.null(result$error)) {
    return(tags$pre(class = "text-danger", result$error))
  }
  recs <- result$records
  fields <- result$fields
  switch(card$type,
    metric = {
      value <- if (length(recs) && length(fields)) flatten_value(recs[[1]][[fields[[1]]]]) else "—"
      tags$div(class = "memdash-metric",
               tags$div(class = "memdash-metric-value", value),
               tags$div(class = "memdash-metric-label", if (length(fields)) fields[[1]] else ""))
    },
    table = DT::dataTableOutput(card_output_id(paste0(card$id, "_tbl"))),
    graph = visNetwork::visNetworkOutput(card_output_id(paste0(card$id, "_net")), height = "320px"),
    bar = plotly::plotlyOutput(card_output_id(paste0(card$id, "_plt")), height = "300px"),
    line = plotly::plotlyOutput(card_output_id(paste0(card$id, "_plt")), height = "300px"),
    pie = plotly::plotlyOutput(card_output_id(paste0(card$id, "_plt")), height = "300px"),
    text = uiOutput(card_output_id(paste0(card$id, "_md"))),
    json = verbatimTextOutput(card_output_id(paste0(card$id, "_js"))),
    tags$p("Unknown card type")
  )
}

#' Build the memdash Shiny app
#'
#' @param cards Card definitions, see \code{\link{default_cards}}.
#' @param uri Default Bolt URI shown in the connection dialog.
#' @return A \code{shiny.appobj}.
#' @export
memdash_app <- function(cards = default_cards(), uri = "bolt://localhost:7687") {
  card_ids <- vapply(cards, function(c) c$id, character(1))

  shiny::addResourcePath("memdash-assets", system.file("app", "www", package = "memdash"))

  ui <- bslib::page_fluid(
    theme = bslib::bs_theme(bg = "#10131a", fg = "#e8eaf0", primary = "#3d7bfd"),
    tags$head(tags$link(rel = "stylesheet", href = "memdash-assets/memdash.css")),
    bslib::card(
      bslib::card_header("memdash — Shiny dashboard for Memgraph"),
      shiny::fluidRow(
        shiny::column(3, shiny::textInput("uri", "Bolt URI", value = uri)),
        shiny::column(2, shiny::textInput("username", "Username", value = "")),
        shiny::column(2, shiny::passwordInput("password", "Password", value = "")),
        shiny::column(2, shiny::actionButton("connect", "Connect", class = "btn-primary")),
        shiny::column(1, shiny::actionButton("seed", "Load demo data", class = "btn-outline-secondary")),
        shiny::column(1, shiny::actionButton("run_all", "Run all", class = "btn-outline-primary")),
        shiny::column(1, shiny::numericInput("refresh", "Refresh (s)", value = 0, min = 0, step = 5))
      ),
      shiny::textOutput("conn_status")
    ),
    shiny::uiOutput("card_grid")
  )

  server <- function(input, output, session) {
    values <- shiny::reactiveValues(results = setNames(vector("list", length(cards)), card_ids), connected = FALSE)

    run_one <- function(card) {
      tryCatch(
        memgraph_query(card$cypher, card$params %||% list()),
        error = function(e) list(records = list(), fields = character(0), error = conditionMessage(e))
      )
    }

    shiny::observeEvent(input$connect, {
      tryCatch({
        memgraph_connect(input$uri, input$username, input$password)
        values$connected <- TRUE
        output$conn_status <- shiny::renderText(paste("Connected to", input$uri))
      }, error = function(e) {
        values$connected <- FALSE
        output$conn_status <- shiny::renderText(paste("Connection failed:", conditionMessage(e)))
      })
    })

    shiny::observeEvent(input$seed, {
      shiny::req(values$connected)
      tryCatch(memdash_seed_demo(), error = function(e) NULL)
      for (card in cards) values$results[[card$id]] <- run_one(card)
    })

    timer <- shiny::reactiveTimer(1000)
    shiny::observe({
      timer()
      shiny::isolate({
        if (values$connected && input$refresh > 0 && as.integer(Sys.time()) %% input$refresh == 0) {
          for (card in cards) values$results[[card$id]] <- run_one(card)
        }
      })
    })

    shiny::observeEvent(input$run_all, {
      shiny::req(values$connected)
      for (card in cards) values$results[[card$id]] <- run_one(card)
    })

    output$card_grid <- shiny::renderUI({
      cols <- lapply(cards, function(card) {
        bslib::layout_column_wrap(
          width = 1/2,
          bslib::card(
            bslib::card_header(card$title, class = "memdash-card-header"),
            bslib::card_body(render_card(card, values$results[[card$id]]))
          )
        )
      })
      do.call(shiny::tagList, cols)
    })

    for (card in cards) {
      local({
        card_local <- card
        shiny::observe({
          res <- values$results[[card_local$id]]
          if (is.null(res)) return()
          switch(card_local$type,
            table = {
              output[[card_output_id(paste0(card_local$id, "_tbl"))]] <- DT::renderDT({
                DT::datatable(records_to_df(res$records, res$fields), options = list(pageLength = 10))
              })
            },
            graph = {
              output[[card_output_id(paste0(card_local$id, "_net"))]] <- visNetwork::renderVisNetwork({
                g <- records_to_graph(res$records)
                if (!length(g$nodes)) return(visNetwork::visNetwork(data.frame(id = "x", label = "no graph data"), data.frame()))
                visNetwork::visNetwork(
                  visNetwork::toVisNetworkData(list(
                    nodes = do.call(rbind, lapply(g$nodes, function(n) data.frame(
                      id = n$id, label = n$label, title = n$title, group = n$group, shape = n$shape,
                      stringsAsFactors = FALSE
                    ))),
                    edges = if (length(g$edges)) do.call(rbind, lapply(g$edges, function(e) data.frame(
                      id = e$id, from = e$from, to = e$to, label = e$label, title = e$title,
                      stringsAsFactors = FALSE
                    ))) else data.frame()
                  ))
                ) %>% visNetwork::visPhysics(solver = "forceAtlas2Based")
              })
            },
            bar = {
              output[[card_output_id(paste0(card_local$id, "_plt"))]] <- plotly::renderPlotly({
                df <- records_to_df(res$records, res$fields)
                if (ncol(df) < 2) return(NULL)
                plotly::plot_ly(df, x = ~.data[[names(df)[1]]], y = ~.data[[names(df)[2]]],
                                type = "bar", name = names(df)[2])
              })
            },
            line = {
              output[[card_output_id(paste0(card_local$id, "_plt"))]] <- plotly::renderPlotly({
                df <- records_to_df(res$records, res$fields)
                if (ncol(df) < 2) return(NULL)
                plotly::plot_ly(df, x = ~.data[[names(df)[1]]], y = ~.data[[names(df)[2]]],
                                type = "scatter", mode = "lines+markers", name = names(df)[2])
              })
            },
            pie = {
              output[[card_output_id(paste0(card_local$id, "_plt"))]] <- plotly::renderPlotly({
                df <- records_to_df(res$records, res$fields)
                if (ncol(df) < 2) return(NULL)
                plotly::plot_ly(df, labels = ~.data[[names(df)[1]]], values = ~as.numeric(.data[[names(df)[2]]]),
                                type = "pie")
              })
            },
            text = {
              output[[card_output_id(paste0(card_local$id, "_md"))]] <- shiny::renderUI({
                if (!length(res$records)) return(NULL)
                shiny::HTML(markdown::markdownToHTML(text = flatten_value(res$records[[1]][[res$fields[[1]]]]), fragment.only = TRUE))
              })
            },
            json = {
              output[[card_output_id(paste0(card_local$id, "_js"))]] <- shiny::renderText({
                jsonlite::toJSON(res$records, auto_unbox = TRUE, pretty = TRUE)
              })
            }
          )
        })
      })
    }
  }

  shiny::shinyApp(ui, server)
}

#' Launch the memdash dashboard
#' @export
run_memdash <- function(...) {
  shiny::runApp(memdash_app(...))
}

`%||%` <- function(a, b) if (is.null(a)) b else a
