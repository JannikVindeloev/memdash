card_output_id <- function(id) paste0("card_", id)

run_card_query <- function(card) {
  tryCatch(
    memgraph_query(card$cypher, card$params %||% list()),
    error = function(e) list(records = list(), fields = character(0), error = conditionMessage(e))
  )
}

card_body_ui <- function(card) {
  switch(card$type,
    metric = shiny::uiOutput(card_output_id(paste0(card$id, "_body"))),
    table = DT::dataTableOutput(card_output_id(paste0(card$id, "_tbl"))),
    graph = visNetwork::visNetworkOutput(card_output_id(paste0(card$id, "_net")), height = "320px"),
    bar = plotly::plotlyOutput(card_output_id(paste0(card$id, "_plt")), height = "300px"),
    line = plotly::plotlyOutput(card_output_id(paste0(card$id, "_plt")), height = "300px"),
    pie = plotly::plotlyOutput(card_output_id(paste0(card$id, "_plt")), height = "300px"),
    text = shiny::uiOutput(card_output_id(paste0(card$id, "_md"))),
    json = shiny::verbatimTextOutput(card_output_id(paste0(card$id, "_js"))),
    shiny::p("Unknown card type")
  )
}

#' Build the memdash Shiny app (dashboard builder)
#'
#' @param cards Card definitions, see \code{\link{default_cards}()} and
#'   \code{\link{new_card}()}. Load persisted dashboards with
#'   \code{\link{load_dashboard}()}.
#' @param uri Default Bolt URI shown in the connection dialog.
#' @param database Default tenant database shown in the connection dialog
#'   (Memgraph Enterprise multi-tenancy; default \code{stxp4rd}).
#' @param read_only When \code{TRUE}, the dashboard renders for viewing only:
#'   add/edit/delete controls are hidden and card definitions cannot change.
#'   Viewers can still connect, run queries, refresh and save a copy. Note this
#'   is an app-level flag; the JSON file itself remains editable text.
#' @param dashboard_file Optional path to a dashboard JSON file; cards are loaded
#'   from it and the app starts in read-only viewing mode.
#' @return A \code{shiny.appobj}.
#' @export
memdash_app <- function(cards = default_cards(), uri = "bolt://localhost:7687",
                        read_only = FALSE, dashboard_file = NULL,
                        database = "stxp4rd") {
  if (!is.null(dashboard_file)) {
    loaded <- load_dashboard(dashboard_file)
    cards <- loaded$cards
    read_only <- TRUE
  }
  editing <- shiny::reactiveVal(NULL)

  shiny::addResourcePath("memdash-assets", system.file("app", "www", package = "memdash"))

  ui <- bslib::page_fluid(
    theme = bslib::bs_theme(bg = "#10131a", fg = "#e8eaf0", primary = "#3d7bfd"),
    shiny::tags$head(shiny::tags$link(rel = "stylesheet", href = "memdash-assets/memdash.css")),
    bslib::card(
      bslib::card_header(
        "memdash — Shiny dashboard for Memgraph",
        if (read_only) shiny::tags$span(class = "badge bg-secondary ms-2", "read-only")
      ),
      shiny::fluidRow(
        shiny::column(3, shiny::textInput("uri", "Bolt URI", value = uri)),
        shiny::column(2, shiny::textInput("username", "Username", value = "")),
        shiny::column(2, shiny::passwordInput("password", "Password", value = "")),
        shiny::column(2, shiny::textInput("database", "Tenant database", value = database)),
        shiny::column(1, shiny::actionButton("connect", "Connect", class = "btn-primary")),
        shiny::column(1, shiny::actionButton("seed", "Load demo data", class = "btn-outline-secondary"))
      ),
      shiny::fluidRow(
        if (!read_only) shiny::column(2, shiny::actionButton("add_card", "+ Add card", class = "btn-success")),
        shiny::column(2, shiny::downloadButton("save_json", "Save dashboard JSON", class = "btn-outline-info")),
        shiny::column(3, shiny::fileInput("load_json", NULL, accept = ".json", buttonLabel = "Load JSON…", placeholder = "no file")),
        shiny::column(if (!read_only) 2 else 3, shiny::actionButton("run_all", "Run all", class = "btn-outline-primary")),
        shiny::column(if (!read_only) 3 else 4, shiny::numericInput("refresh", "Refresh all (s, 0=off)", value = 0, min = 0, step = 5))
      ),
      shiny::textOutput("conn_status")
    ),
    shiny::uiOutput("card_grid")
  )

  server <- function(input, output, session) {
    values <- shiny::reactiveValues(
      cards = cards,
      results = setNames(vector("list", length(cards)), vapply(cards, function(c) c$id, character(1))),
      connected = FALSE
    )

    run_all <- function() {
      for (card in values$cards) values$results[[card$id]] <- run_card_query(card)
    }

    register_card_outputs <- function(card) {
      out_id <- card_output_id(paste0(card$id, "_body"))
      if (card$type == "metric") {
        output[[out_id]] <- shiny::renderUI({
          res <- values$results[[card$id]]
          if (is.null(res)) return(shiny::p(class = "text-secondary", "No data yet — press Run."))
          if (!is.null(res$error)) return(shiny::tags$pre(class = "text-danger", res$error))
          value <- if (length(res$records) && length(res$fields)) flatten_value(res$records[[1]][[res$fields[[1]]]]) else "—"
          shiny::tags$div(class = "memdash-metric",
            shiny::tags$div(class = "memdash-metric-value", value),
            shiny::tags$div(class = "memdash-metric-label", if (length(res$fields)) res$fields[[1]] else ""))
        })
      }
      if (card$type == "table") {
        output[[card_output_id(paste0(card$id, "_tbl"))]] <- DT::renderDT({
          res <- values$results[[card$id]]
          shiny::req(res)
          if (!is.null(res$error)) return(DT::datatable(data.frame(error = res$error)))
          DT::datatable(records_to_df(res$records, res$fields), options = list(pageLength = 10))
        })
      }
      if (card$type == "graph") {
        output[[card_output_id(paste0(card$id, "_net"))]] <- visNetwork::renderVisNetwork({
          res <- values$results[[card$id]]
          shiny::req(res)
          if (!is.null(res$error)) return(visNetwork::visNetwork(data.frame(id = "x", label = res$error), data.frame()))
          g <- records_to_graph(res$records)
          if (!length(g$nodes)) return(visNetwork::visNetwork(data.frame(id = "x", label = "no graph data"), data.frame()))
          nodes <- do.call(rbind, lapply(g$nodes, function(n) data.frame(
            id = n$id, label = n$label, title = n$title, group = n$group, shape = n$shape,
            stringsAsFactors = FALSE)))
          edges <- if (length(g$edges)) do.call(rbind, lapply(g$edges, function(e) data.frame(
            id = e$id, from = e$from, to = e$to, label = e$label, title = e$title,
            stringsAsFactors = FALSE))) else data.frame()
          visNetwork::visNetwork(nodes, edges) %>%
            visNetwork::visPhysics(solver = "forceAtlas2Based") %>%
            visNetwork::visOptions(highlightNearest = TRUE)
        })
      }
      if (card$type %in% c("bar", "line", "pie")) {
        output[[card_output_id(paste0(card$id, "_plt"))]] <- plotly::renderPlotly({
          res <- values$results[[card$id]]
          shiny::req(res)
          df <- records_to_df(res$records, res$fields)
          if (nrow(df) == 0 || ncol(df) < 2) return(NULL)
          x <- df[[1]]
          y <- suppressWarnings(as.numeric(df[[2]]))
          if (card$type == "bar") {
            plotly::plot_ly(x = x, y = y, type = "bar", name = names(df)[2])
          } else if (card$type == "line") {
            plotly::plot_ly(x = x, y = y, type = "scatter", mode = "lines+markers", name = names(df)[2])
          } else {
            plotly::plot_ly(labels = x, values = y, type = "pie")
          }
        })
      }
      if (card$type == "text") {
        output[[card_output_id(paste0(card$id, "_md"))]] <- shiny::renderUI({
          res <- values$results[[card$id]]
          shiny::req(res)
          if (!length(res$records)) return(NULL)
          shiny::HTML(markdown::markdownToHTML(text = flatten_value(res$records[[1]][[res$fields[[1]]]]), fragment.only = TRUE))
        })
      }
      if (card$type == "json") {
        output[[card_output_id(paste0(card$id, "_js"))]] <- shiny::renderText({
          res <- values$results[[card$id]]
          shiny::req(res)
          jsonlite::toJSON(res$records, auto_unbox = TRUE, pretty = TRUE)
        })
      }
    }

    registered <- shiny::reactiveVal(character(0))
    register_card <- function(card, force = FALSE) {
      if (!force && card$id %in% registered()) return()
      register_card_outputs(card)
      shiny::local({
        card_id <- card$id
        shiny::observeEvent(input[[paste0("run_", card_id)]], {
          shiny::req(values$connected)
          card_now <- values$cards[[which(vapply(values$cards, function(c) c$id, character(1)) == card_id)]]
          if (!is.null(card_now)) values$results[[card_id]] <- run_card_query(card_now)
        })
        if (!read_only) {
          shiny::observeEvent(input[[paste0("edit_", card_id)]], {
            editing(card_id)
            card_now <- values$cards[[which(vapply(values$cards, function(c) c$id, character(1)) == card_id)]]
            if (is.null(card_now)) return()
            shiny::updateTextInput(session, "edit_title", value = card_now$title)
            shiny::updateSelectInput(session, "edit_type", selected = card_now$type)
            shiny::updateTextAreaInput(session, "edit_cypher", value = card_now$cypher)
            shiny::updateTextAreaInput(session, "edit_params", value = params_to_text(card_now$params))
            shiny::updateNumericInput(session, "edit_refresh", value = card_now$refresh %||% 0)
            shiny::updateSelectInput(session, "edit_width", selected = card_now$width %||% "half")
            shiny::showModal(card_editor_modal())
          })
        }
      })
      registered(c(registered(), card$id))
    }

    for (card in values$cards) register_card(card)

    shiny::observeEvent(input$connect, {
      tryCatch({
        memgraph_connect(input$uri, input$username, input$password, database = input$database %||% "stxp4rd")
        values$connected <- TRUE
        output$conn_status <- shiny::renderText(paste("Connected to", input$uri))
        run_all()
      }, error = function(e) {
        values$connected <- FALSE
        output$conn_status <- shiny::renderText(paste("Connection failed:", conditionMessage(e)))
      })
    })

    shiny::observeEvent(input$seed, {
      shiny::req(values$connected)
      tryCatch(memdash_seed_demo(), error = function(e) NULL)
      run_all()
    })

    shiny::observeEvent(input$run_all, {
      shiny::req(values$connected)
      run_all()
    })

    timer <- shiny::reactiveTimer(1000)
    shiny::observe({
      timer()
      shiny::isolate({
        if (!values$connected) return()
        now <- as.integer(Sys.time())
        if (input$refresh > 0 && now %% input$refresh == 0) run_all()
        for (card in values$cards) {
          if ((card$refresh %||% 0) > 0 && now %% card$refresh == 0) {
            values$results[[card$id]] <- run_card_query(card)
          }
        }
      })
    })

    shiny::observeEvent(input$add_card, {
      if (read_only) return()
      card <- new_card(title = paste("Card", length(values$cards) + 1))
      values$cards <- c(values$cards, list(card))
      values$results[[card$id]] <- NULL
      register_card(card, force = TRUE)
      editing(card$id)
      shiny::showModal(card_editor_modal())
    })

    shiny::observeEvent(input$load_json$datapath, {
      tryCatch({
        loaded <- load_dashboard(input$load_json$datapath)
        values$cards <- loaded$cards
        values$results <- setNames(vector("list", length(loaded$cards)), vapply(loaded$cards, function(c) c$id, character(1)))
        registered(character(0))
        for (card in values$cards) register_card(card)
        if (values$connected) run_all()
        shiny::showNotification(paste("Loaded dashboard:", loaded$name), type = "message")
      }, error = function(e) shiny::showNotification(paste("Load failed:", conditionMessage(e)), type = "error"))
    })

    output$save_json <- shiny::downloadHandler(
      filename = function() paste0("memdash-", format(Sys.Date(), "%Y%m%d"), ".json"),
      content = function(file) save_dashboard(values$cards, file, name = "memdash dashboard")
    )

    card_editor_modal <- function() {
      shiny::modalDialog(
        title = "Edit card",
        easyClose = TRUE,
        size = "l",
        shiny::textInput("edit_title", "Title"),
        shiny::selectInput("edit_type", "Visualization", choices = setNames(CARD_TYPES, CARD_TYPES)),
        shiny::textAreaInput("edit_cypher", "Cypher query", rows = 8),
        shiny::textAreaInput("edit_params", "Parameters ($key in query, one per line: key=value)", rows = 2),
        shiny::numericInput("edit_refresh", "Auto-refresh (seconds, 0 = off)", value = 0, min = 0),
        shiny::selectInput("edit_width", "Width", choices = c(half = "half", full = "full")),
        footer = shiny::tagList(
          shiny::actionButton("edit_delete", "Delete", class = "btn-danger"),
          shiny::actionButton("edit_save", "Save", class = "btn-primary"),
          shiny::modalButton("Cancel")
        )
      )
    }

    shiny::observeEvent(input$edit_save, {
      id <- editing()
      shiny::req(id)
      idx <- which(vapply(values$cards, function(c) c$id, character(1)) == id)
      card <- values$cards[[idx]]
      card$title <- input$edit_title
      card$type <- input$edit_type
      card$cypher <- input$edit_cypher
      card$params <- text_to_params(input$edit_params)
      card$refresh <- input$edit_refresh
      card$width <- input$edit_width
      values$cards[[idx]] <- card
      register_card(card, force = TRUE)
      values$results[[id]] <- run_card_query(card)
      shiny::removeModal()
      editing(NULL)
    })

    shiny::observeEvent(input$edit_delete, {
      id <- editing()
      shiny::req(id)
      values$cards <- values$cards[vapply(values$cards, function(c) c$id, character(1)) != id]
      values$results[[id]] <- NULL
      shiny::removeModal()
      editing(NULL)
    })

    output$card_grid <- shiny::renderUI({
      cards <- values$cards
      if (!length(cards)) {
        return(shiny::p(class = "text-secondary", "No cards yet — press \"+ Add card\" or load a dashboard JSON."))
      }
      do.call(shiny::tagList, lapply(cards, function(card) {
        res <- values$results[[card$id]]
        header <- shiny::tags$div(
          class = "memdash-card-header",
          shiny::tags$span(class = "me-2", card$title),
          shiny::tags$span(class = "badge bg-secondary", card$type),
          if (!read_only) shiny::tags$span(
            shiny::actionButton(paste0("edit_", card$id), "", icon = shiny::icon("gear"),
                                class = "btn btn-sm btn-outline-light memdash-edit-btn")
          )
        )
        footer <- shiny::tags$div(
          class = "memdash-card-footer",
          shiny::actionButton(paste0("run_", card$id), "Run", class = "btn btn-sm btn-outline-primary"),
          shiny::tags$span(class = "text-secondary ms-2",
            if (!is.null(res) && is.null(res$error)) paste0(length(res$records), " row(s)") else "not run yet")
        )
        bslib::layout_column_wrap(
          width = if (identical(card$width %||% "half", "full")) 1 else 1/2,
          bslib::card(bslib::card_header(header), bslib::card_body(card_body_ui(card)), bslib::card_footer(footer))
        )
      }))
    })

  }

  shiny::shinyApp(ui, server)
}

#' Launch the memdash dashboard builder
#'
#' @param ... Passed to \code{\link[=memdash_app]{memdash_app()}}.
#' @export
run_memdash <- function(...) {
  shiny::runApp(memdash_app(...))
}
