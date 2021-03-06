library(plotly)

navbarPage("Social Media Sentiment in Singapore",
  tabPanel("Case Studies", align="center",
    includeHTML("case_studies.html"),
    br(),
    plotlyOutput("richpoorPlot", width="60%", height="600"),
    includeMarkdown("richpoor.md")
  ),
  tabPanel("Explore",
    sidebarLayout(
      sidebarPanel(
        selectInput('dataset', 'Data', c("Twitter", "Instagram"), selected="Twitter"),
        selectInput('sent', 'Data Type', c("Sentiment", "Positive", "Negative", "Count"), selected="Sentiment"),
        selectInput('func', 'Aggregate Method', c("Mean", "Sum"), selected="Mean"),
        numericInput('binSize', 'Hexagon Size', 0.02,
                     min = 0.01, max = 0.05),
        numericInput('minPosts', 'Minimum Posts Threshold', 100,
                     min = 0, max = 1000),
        checkboxInput('showMap', "Show Singapore Map", FALSE),
        width=3
      ),
      mainPanel(align="center",
        plotlyOutput('plotInteractive', width="100%", height="500px"),
        br(),
        uiOutput("sliderOutput", width="100%")
      )
    )
  ),
  tabPanel("About",
    includeMarkdown("about.md")
  )
)
