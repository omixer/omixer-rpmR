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
  navset_card_underline(
    resultPanel("Abundance", "abundance"),
    resultPanel("Coverage", "coverage")
  )
)

server <- function(input, output, session) {
  # this session's tables, NULL until a run succeeds
  results <- reactiveVal(NULL)

  observeEvent(input$run, {
    results(NULL)
    if (is.null(input$input_file)) {
      showNotification("Choose an input table first.", type = "warning")
      return()
    }
    modules <- tryCatch(
      rpm(
        x = input$input_file$datapath,
        minimum.coverage = if (input$automatic_coverage) -1 else input$minimum_coverage,
        score.estimator = input$score_estimator,
        annotation = input$annotation,
        module.db = loadDB(input$module_db),
        normalize.by.length = input$normalize_by_length,
        distribute = input$distribute,
        complex.rule = input$complex_rule,
        ignore.taxonomy = input$ignore_taxonomy
      ),
      error = function(e) {
        showNotification(conditionMessage(e), type = "error", duration = NULL)
        NULL
      }
    )
    if (!is.null(modules)) {
      results(list(abundance = asDataFrame(modules, "abundance"), coverage = asDataFrame(modules, "coverage")))
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
}

shinyApp(ui = ui, server = server)
