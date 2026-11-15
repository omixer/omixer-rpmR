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

# a chart with the value under the pointer below it
chartOutput <- function(id) {
  tagList(
    plotOutput(id, height = "auto", hover = hoverOpts(paste0(id, "_hover"), delay = 80, delayType = "debounce")),
    div(class = "small text-muted", textOutput(paste0(id, "_value")))
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
      chartOutput("heatmap")
    ),
    nav_panel("Taxa", uiOutput("taxa_panel")),
    nav_panel("Taxa \u00d7 modules", uiOutput("chord_panel")),
    nav_panel(
      "Coverage cutoff",
      chartOutput("cutoff"),
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
  output$heatmap <- renderPlot(
    {
      value <- if (input$heatmap_measure == "abundance") "abundance (log scale)" else "coverage"
      plotHeatmap(heatmap(), sprintf("Top %d modules by mean %s", nrow(heatmap()), value),
        log = input$heatmap_measure == "abundance"
      )
    },
    height = function() 170 + 18 * max(5, nrow(heatmap()))
  )
  output$heatmap_value <- renderText({
    hover <- input$heatmap_hover
    values <- heatmap()
    cell <- if (!is.null(hover)) c(nrow(values) - round(hover$y) + 1, round(hover$x)) else c(0, 0)
    if (!all(cell >= 1 & cell <= dim(values))) {
      return("Point at a cell to see its value.")
    }
    value <- values[cell[1], cell[2]]
    shown <- if (is.na(value)) {
      "not reported"
    } else if (input$heatmap_measure == "abundance") {
      signif(10^value, 4)
    } else {
      signif(value, 3)
    }
    sprintf("%s, %s: %s", colnames(values)[cell[2]], rownames(values)[cell[1]], shown)
  })

  # A3: the taxa of a module, for results per taxon
  output$taxa_panel <- renderUI({
    req(results())
    if (!"Taxon" %in% colnames(results()$abundance)) {
      return(perTaxonOnly("Taxon contributions"))
    }
    tagList(
      selectInput("taxa_module", "Module", taxonModules(results()$abundance), width = "100%"),
      chartOutput("taxa"),
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
  output$taxa <- renderPlot(
    {
      module <- input$taxa_module
      plotTaxa(taxa()$shares, paste(module, getNames(results()$settings$module.db, module)))
    },
    height = 460
  )
  output$taxa_value <- renderText({
    hover <- input$taxa_hover
    shares <- taxa()$shares
    sample <- if (is.null(hover)) 0 else round(hover$x)
    if (sample < 1 || sample > ncol(shares) || hover$y < 0 || hover$y > 1) {
      return("Point at a bar to see a taxon's share.")
    }
    taxon <- which(hover$y <= cumsum(shares[, sample]))[1]
    if (is.na(taxon)) {
      return(sprintf("%s: no taxon carries this module.", colnames(shares)[sample]))
    }
    sprintf(
      "%s, %s: %.1f%% (abundance %s)", colnames(shares)[sample], rownames(shares)[taxon],
      100 * shares[taxon, sample], signif(taxa()$abundance[taxon, sample], 4)
    )
  })

  # the taxa and modules with the highest abundance, linked by the module's abundance in the taxon (circlize)
  output$chord_panel <- renderUI({
    req(results())
    if (!"Taxon" %in% colnames(results()$abundance)) {
      return(perTaxonOnly("The links between taxa and modules"))
    }
    if (!requireNamespace("circlize", quietly = TRUE)) {
      return(p(class = "text-muted", "This chart needs the circlize package: install.packages(\"circlize\")."))
    }
    samples <- sampleColumns(results()$abundance)
    tagList(
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        selectInput("chord_sample", "Samples", c("All samples (sum)" = "", stats::setNames(samples, samples))),
        sliderInput("chord_taxa", "Taxa", min = 5, max = 30, value = 15, step = 1),
        sliderInput("chord_modules", "Modules", min = 5, max = 30, value = 15, step = 1),
        selectInput("chord_highlight", "Highlight", c("None" = ""))
      ),
      plotOutput("chord", height = "auto"),
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
  # the highlight choices follow the taxa and modules shown, and keep the selection while it is shown
  observe({
    choices <- list(
      "None" = "", "Taxa" = stats::setNames(chord()$taxa, chord()$taxa),
      "Modules" = stats::setNames(chord()$modules, chordModuleNames())
    )
    selected <- isolate(input$chord_highlight)
    keep <- !is.null(selected) && selected %in% c(chord()$taxa, chord()$modules)
    updateSelectInput(session, "chord_highlight", choices = choices, selected = if (keep) selected else "")
  })
  output$chord <- renderPlot(
    {
      where <- if (nzchar(chordSample())) paste("sample", chordSample()) else "all samples"
      subtitle <- sprintf(
        "The %d taxa and %d modules with the highest abundance (%.0f%% of the total), linked by %s",
        length(chord()$taxa), length(chord()$modules), 100 * chord()$share, "the module's abundance in the taxon"
      )
      plotChord(chord(), input$chord_highlight, paste("Taxa and modules,", where), subtitle)
    },
    height = 760
  )
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
  output$cutoff <- renderPlot(
    plotCoverage(distribution(), results()$cutoff, results()$automatic),
    height = 440
  )
  output$cutoff_value <- renderText({
    hover <- input$cutoff_hover
    points <- distribution()
    nearest <- if (is.null(hover) || nrow(points) == 0) NA else which.min(abs(points$coverage - hover$x))
    if (is.na(nearest) || abs(points$coverage[nearest] - hover$x) > 0.03) {
      total <- max(c(0, points$kept))
      return(sprintf("%d module observations in total. Point at a dot to see what a cutoff keeps.", total))
    }
    sprintf("Cutoff %s keeps %d module observations.", format(points$coverage[nearest]), points$kept[nearest])
  })
}

shinyApp(ui = ui, server = server)
