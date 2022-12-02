library(shiny)
library(shinymaterial)
library(omixerRpm)

# form fields names 
fields <- c("matrix", "module.db", "annotation", "minimum.coverage", "score.estimator", "normalize.by.length", "distribute")

# save a response
runRpm <- function(input) {

  # load the selected module database for mapping 
  module.db <- loadDB(input$module.db)
  # get the annotation value from the first charachter of the input 
  annotation <- substring(input$annotation, 1, 1)
  # run rpm mapping with user input
  modules <- rpm(x = input$matrix$datapath, minimum.coverage = input$minimum.coverage, annotation = annotation, module.db = module.db)
  # collect module names
  module.names <- apply(data.frame(Module = modules@annotation$Module), 1, function(x) getNames(modules@db, x))
  # create a dataframe with modules, names and abundance
  abundance <<- cbind(modules@annotation, Names = module.names, modules@abundance)
  # create a dataframe with modules, names and coverage
  coverage <<- cbind(modules@annotation, Names = module.names, modules@coverage)
}

# Load the response
loadData <- function(target) {
  if (target == "abundance" && exists("abundance")) {
    abundance
  } else if (target == "coverage" && exists("coverage")) {
    coverage
  }
}

# Define UI for app that draws a histogram ----
ui <- material_page(
  title = "ShinyRpm",
  primary_theme_color = "#2d3032",
  secondary_theme_color = "#428bca",
  tags$br(),
  material_row(
    material_column(
      width = 2,
      material_card(
        depth = 1,
        # Input: Select a file ----
        fileInput("matrix", "Choose TSV inpule File",
                  multiple = FALSE,
                  accept = c("text/tsv",
                             "text/tab-separated-values,text/plain", ".txt,.tsv")),
        # Input: dropdown for the database
        selectInput(inputId = "module.db",
                    label = "Module database for mapping",
                    choices = listDB()),
        # Input: dropdown for the annotation type
        selectInput(inputId = "annotation",
                    label = "Input file annotation",
                    choices = c("1: orthologs only", "2: taxonomic annotation followed by orthologs")),
        # -c,--coverage                The minimum coverage cut-off to accept a module [0.0 to 1.0].
        # Defaults to -1, where the coverage is learned from the coverage distribution of all modules
        sliderInput(inputId = "minimum.coverage",
                    label = "The minimum pathway coverage to consider a module present",
                    min = 0,
                    max = 1,
                    value = 0.3),
        # Input: dropdown for the score estimator
        selectInput(inputId = "score.estimator",
                    label = "The score estimatore",
                    choices = c("median", "average", "sum", "min")),

        checkboxInput(inputId = "normalize.by.length",
                      label = "Divide module score by its length",
                      value = F),

        checkboxInput(inputId = "distribute",
                      label = "[Experimental feature] When an ortholog is shared by N modules then its abundance is divided by N.",
                      value = F),

        actionButton("submit", "Submit")
      ),
      p("Designed by", a( "Omixer Solutions", href = "https://omixer.io/", target="_blank"))
    ),
    material_column(
      width = 9,
      material_card(
        depth = 1,
        h3('Abundance', downloadButton('abundance.download', '')),
        DT::dataTableOutput("abundance")
      ),
      material_card(
        depth = 1,
        h3('Coverage', downloadButton('abundance.coverage', '')),
        DT::dataTableOutput("coverage")
      )
    )
  )
)

server <- function(input, output) {

  # collect user form input
  formData <- reactive({
    data <- sapply(fields, function(x) input[[x]])
    data
  })

  # run omixer-rpm when the Submit button is clicked
  observeEvent(input$submit, {
    runRpm(formData())
  })

  # render the response
  output$abundance <- DT::renderDataTable({
    input$submit
    loadData("abundance")
  })

  output$coverage <- DT::renderDataTable({
    input$submit
    loadData("coverage")
  })

  output$abundance.download = downloadHandler('modules.abundance.tsv', content = function(file) {
    write.table(loadData("abundance"), file, row.names = FALSE, sep = "\t", quote = FALSE)
  })

  output$coverage.download = downloadHandler('modules.coverage.tsv', content = function(file) {
    write.table(loadData("coverage"), file, row.names = FALSE, sep = "\t", quote = FALSE)
  })
}

shinyApp(ui = ui, server = server)