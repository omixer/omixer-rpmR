library(shiny)
library(omixerRpm)

# form fields names 
fields <- c("matrix", "module.db", "annotation", "minimum.coverage", "score.estimator", "normalize.by.length", "distribute")

# save a response
runRpm <- function(input) {

  # load the selected module database for mapping 
  module.db <- loadDB(input$module.db)
  # get the annotation value from the first charachter of the input 
  annotation <- substring(input$annotation, 1, 1)
  # run rpm rpm mapping with user input 
  modules <- rpm(x = input$matrix$datapath, minimum.coverage = input$minimum.coverage, annotation = annotation, module.db = module.db)

  data <- modules@coverage

  response <<- data
}

# Load the response
loadData <- function() {
  if (exists("response")) {
    response
  }
}

# Define UI for app that draws a histogram ----
ui <- fluidPage(

  # App title ----
  titlePanel("ShinyR-omixer-rpm: A Web App for metabolic module profiling of microbiome samples [alpha]"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      # Input: Select a file ----
      fileInput("matrix", "Choose TSV inpule File",
                multiple = FALSE,
                accept = c("text/tsv",
                         "text/tab-separated-values,text/plain", ".txt,.tsv")),

      # Horizontal line ----
      tags$hr(),

      # Input: dropdown for the database
      selectInput(inputId = "module.db",
                  label = "Database: module database for mapping",
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

    # Main panel for displaying outputs
    mainPanel(
      DT::dataTableOutput("response"), tags$hr()
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
    output$response <- DT::renderDataTable({
      input$submit
      loadData()
    })

}

shinyApp(ui = ui, server = server)