library(shiny)
library(bslib)
library(omixerRpm)

# Shiny accepts uploads up to 5 MB by default; KO tables are often larger
if (is.null(getOption("shiny.maxRequestSize"))) {
  options(shiny.maxRequestSize = 1024^3)
}

resultPanel <- function(title, id) {
  nav_panel(
    title,
    div(downloadButton(paste0("download_", id), "Download TSV", class = "btn-sm")),
    DT::DTOutput(id)
  )
}

# the message of a tab that needs results per taxon
perTaxonOnly <- function(what) {
  p(
    class = "text-muted",
    what, "need results per taxon: the input format \"Taxon, then orthologs\" or a stratified HUMAnN table,",
    "without \"One result per sample\"."
  )
}

# the d3 script of the taxa x modules chord diagram (the app runs in its directory)
chordScript <- normalizePath("chord.js")

# a ggplot2 chart (R/plots.R) as an interactive plotly chart: the `text` aesthetic as tooltip, the title and subtitle
# kept (ggplotly() drops subtitles), no plotly logo; legend "reversed" lists the traces from the last (plotly ignores
# ggplot2's reversed legends)
interactive <- function(chart, legend = "normal") {
  labels <- ggplot2::get_labs(chart)
  title <- if (is.null(labels$subtitle)) {
    labels$title
  } else {
    sprintf("%s<br><span style='font-size:12px;color:%s'>%s</span>", labels$title, ink$secondary, labels$subtitle)
  }
  plotly::ggplotly(chart, tooltip = "text") |>
    plotly::layout(
      title = list(text = title, x = 0.01, xanchor = "left", xref = "container"), margin = list(t = 70),
      legend = list(traceorder = legend)
    ) |>
    plotly::config(displaylogo = FALSE, modeBarButtonsToRemove = c("lasso2d", "select2d"))
}

ui <- page_sidebar(
  title = "Omixer-RPM",
  sidebar = sidebar(
    width = 340,
    fileInput("input_file", "Input table (TSV)", accept = c(".tsv", ".txt", "text/tab-separated-values")),
    selectInput("annotation", "Input format",
      choices = c(
        "Orthologs only" = "1",
        "Taxon, then orthologs" = "2",
        "HUMAnN KO table (humann_regroup_table, joined)" = "humann"
      )
    ),
    checkboxInput("ignore_taxonomy", "One result per sample (ignore taxa)", FALSE),
    selectInput("module_db", "Module database", choices = listDB(), selected = "GMMs.v1.07"),
    checkboxInput("automatic_coverage", "Learn the coverage cutoff from the data", TRUE),
    conditionalPanel(
      "!input.automatic_coverage",
      sliderInput("minimum_coverage", "Minimum module coverage", min = 0, max = 1, value = 0.3, step = 0.01)
    ),
    selectInput("score_estimator", "Score estimator", choices = c("median", "average", "sum", "min")),
    selectInput("complex_rule", "Complex steps",
      choices = c(
        "Present when any subunit is observed" = "any",
        "Present when all subunits are observed" = "all"
      )
    ),
    checkboxInput("normalize_by_length", "Divide module score by its length", FALSE),
    checkboxInput("distribute", "Divide a shared ortholog's abundance over its modules (experimental)", FALSE),
    input_task_button("run", "Run"),
    p(class = "small text-muted", "Designed by", a("Omixer Solutions", href = "https://omixer.io/", target = "_blank"))
  ),
  div(
    downloadButton("download_long", "Long table (TSV)", class = "btn-sm"),
    span(class = "small text-muted ms-2", "one row per sample and reported module: abundance and coverage")
  ),
  navset_card_underline(
    resultPanel("Abundance", "abundance"),
    resultPanel("Coverage", "coverage"),
    nav_panel(
      "Heatmap",
      layout_columns(
        col_widths = c(4, 8),
        radioButtons("heatmap_measure", "Value", c("Abundance" = "abundance", "Coverage" = "coverage"), inline = TRUE),
        sliderInput("heatmap_rows", "Modules shown (highest mean first)", min = 5, max = 100, value = 30, step = 5)
      ),
      uiOutput("heatmap_chart")
    ),
    nav_panel("Taxa", uiOutput("taxa_panel")),
    nav_panel("Taxa \u00d7 modules", uiOutput("chord_panel")),
    nav_panel(
      "Coverage cutoff",
      plotly::plotlyOutput("cutoff", height = "460px"),
      p(
        class = "small text-muted",
        "Computed with a second run at cutoff 0 and the same settings, when this tab is first opened."
      )
    )
  )
)

server <- function(input, output, session) {
  # this session's last successful run: its tables, cutoff and settings; NULL until a run succeeds
  results <- reactiveVal(NULL)

  observeEvent(input$run, {
    results(NULL)
    if (is.null(input$input_file)) {
      showNotification("Choose an input table first.", type = "warning")
      return()
    }
    settings <- list(
      x = input$input_file$datapath,
      minimum.coverage = if (input$automatic_coverage) -1 else input$minimum_coverage,
      score.estimator = input$score_estimator,
      annotation = input$annotation,
      module.db = loadDB(input$module_db),
      normalize.by.length = input$normalize_by_length,
      distribute = input$distribute,
      complex.rule = input$complex_rule,
      ignore.taxonomy = input$ignore_taxonomy
    )
    modules <- tryCatch(do.call(rpm, settings), error = function(e) {
      showNotification(conditionMessage(e), type = "error", duration = NULL)
      NULL
    })
    if (!is.null(modules)) {
      results(list(
        abundance = asDataFrame(modules, "abundance"), coverage = asDataFrame(modules, "coverage"),
        cutoff = modules@cutoff, automatic = settings$minimum.coverage == -1, settings = settings
      ))
    }
  })

  for (id in c("abundance", "coverage")) {
    local({
      table <- id
      output[[table]] <- DT::renderDT({
        req(results())
        DT::datatable(results()[[table]], rownames = FALSE, options = list(scrollX = TRUE, pageLength = 25))
      })
      output[[paste0("download_", table)]] <- downloadHandler(
        filename = if (table == "abundance") "modules.tsv" else "modules-coverage.tsv",
        content = function(file) {
          req(results())
          write.table(results()[[table]], file, row.names = FALSE, sep = "\t", quote = FALSE)
        }
      )
    })
  }

  # A4: the long table
  output$download_long <- downloadHandler(
    filename = "modules-long.tsv",
    content = function(file) {
      req(results())
      long <- longTable(results()$abundance, results()$coverage)
      write.table(long, file, row.names = FALSE, sep = "\t", quote = FALSE)
    }
  )

  # A2: the heatmap of the rows with the highest mean
  heatmap <- reactive({
    req(results())
    log <- input$heatmap_measure == "abundance"
    heatmapMatrix(results()[[input$heatmap_measure]], input$heatmap_rows, log = log)
  })
  # the height follows the number of rows
  output$heatmap_chart <- renderUI({
    plotly::plotlyOutput("heatmap", height = paste0(200 + 18 * max(5, nrow(heatmap())), "px"))
  })
  output$heatmap <- plotly::renderPlotly({
    value <- if (input$heatmap_measure == "abundance") "abundance" else "coverage"
    title <- sprintf("Top %d modules by mean %s", nrow(heatmap()), value)
    chart <- interactive(heatmapChart(heatmap(), log = input$heatmap_measure == "abundance", title))
    # the 2px gaps between cells (the heatmap is the first trace), while the cells stay large enough
    if (length(heatmap()) <= 3600) chart <- plotly::style(chart, xgap = 2, ygap = 2, traces = 1)
    chart
  })

  # A3: the taxa of a module, for results per taxon
  output$taxa_panel <- renderUI({
    req(results())
    if (!"Taxon" %in% colnames(results()$abundance)) {
      return(perTaxonOnly("Taxon contributions"))
    }
    tagList(
      selectInput("taxa_module", "Module", taxonModules(results()$abundance), width = "100%"),
      plotly::plotlyOutput("taxa", height = "480px"),
      p(
        class = "small text-muted",
        "Each taxon's abundance is omixer-rpm's estimate of the module in that taxon. The shares are of their sum,",
        "which is not the module's abundance in the whole community. The values are in the Long table."
      )
    )
  })
  taxa <- reactive({
    req(results(), input$taxa_module)
    taxonShares(results()$abundance, input$taxa_module)
  })
  output$taxa <- plotly::renderPlotly({
    module <- input$taxa_module
    interactive(taxaChart(taxa(), paste(module, getNames(results()$settings$module.db, module))), legend = "reversed")
  })

  # the taxa and modules with the highest abundance, linked by the module's abundance in the taxon (d3, chord.js)
  output$chord_panel <- renderUI({
    req(results())
    if (!"Taxon" %in% colnames(results()$abundance)) {
      return(perTaxonOnly("The links between taxa and modules"))
    }
    samples <- sampleColumns(results()$abundance)
    tagList(
      layout_columns(
        col_widths = c(4, 4, 4),
        selectInput("chord_sample", "Samples", c("All samples (sum)" = "", stats::setNames(samples, samples))),
        sliderInput("chord_taxa", "Taxa", min = 5, max = 30, value = 15, step = 1),
        sliderInput("chord_modules", "Modules", min = 5, max = 30, value = 15, step = 1)
      ),
      uiOutput("chord_title"),
      r2d3::d3Output("chord", height = "760px"),
      uiOutput("chord_key")
    )
  })
  # "" for all samples, also before the controls exist
  chordSample <- reactive(if (is.null(input$chord_sample)) "" else input$chord_sample)
  chord <- reactive({
    req(results(), input$chord_taxa, input$chord_modules)
    chordLinks(results()$abundance, chordSample(), input$chord_taxa, input$chord_modules)
  })
  chordModuleNames <- reactive(paste(chord()$modules, getNames(results()$settings$module.db, chord()$modules)))
  output$chord_title <- renderUI({
    where <- if (nzchar(chordSample())) paste("sample", chordSample()) else "all samples"
    tagList(
      h6(class = "mb-0", paste("Taxa and modules,", where)),
      p(class = "small text-muted", sprintf(
        "The %d taxa (light) and %d modules (dark) with the highest abundance (%.0f%% of the total), linked by %s",
        length(chord()$taxa), length(chord()$modules), 100 * chord()$share, "the module's abundance in the taxon."
      ))
    )
  })
  output$chord <- r2d3::renderD3({
    r2d3::r2d3(chordData(chord(), chordModuleNames()), script = chordScript, d3_version = "6", options = chordColours)
  })
  output$chord_key <- renderUI({
    p(
      class = "small text-muted",
      strong("Modules: "), paste(chordModuleNames(), collapse = "; "), br(),
      "A taxon's abundance of a module is omixer-rpm's estimate of the module in that taxon; the values are in the",
      "Long table."
    )
  })

  # A1: the coverage distribution, from a second run at cutoff 0 with the same settings
  distribution <- reactive({
    req(results())
    settings <- utils::modifyList(results()$settings, list(minimum.coverage = 0))
    modules <- tryCatch(do.call(rpm, settings), error = function(e) {
      showNotification(conditionMessage(e), type = "error", duration = NULL)
      NULL
    })
    req(modules)
    coverageDistribution(asDataFrame(modules, "coverage"))
  })
  output$cutoff <- plotly::renderPlotly({
    interactive(coverageChart(distribution(), results()$cutoff, results()$automatic))
  })
}

shinyApp(ui = ui, server = server)
