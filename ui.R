# Define UI 
ui <- fluidPage(
    navbarPage("COVID-19 TRACKER",
               #Choropleth Maps Reporting Worldwide Cases and Deaths
               tabPanel("Worldwide Map of Reported Cases and Deaths",
                        prettyRadioButtons(inputId = "summaryStats",
                                           label = "Select:",
                                           choices = c("Total Cases", "Total Deaths"),
                                           fill=TRUE
                        ), 
                        tags$style(type = "text/css", "#covidMap {height: calc(100vh - 80px) !important;}"),
                        leafletOutput("covidMap")
               ),
               # Time-Series Visualization using dygraphs
               tabPanel("Country Time-Series Visualizations",
                        dateRangeInput("dates", 
                                       "Transmission Period",
                                       start = "2020-01-10", 
                                       end = "2020-12-24"),
                        
                        sidebarLayout(
                            sidebarPanel(
                                uiOutput("casesDeaths"),
                            ),
                            mainPanel(
                                dygraphOutput("covidgraph", height="500px")
                            ),
                        ),
               ),
               navbarMenu("News Article Text Analysis",
                          # Page for word cloud 
                          tabPanel("Word Cloud",
                                   titlePanel("Word Cloud of Most Frequent Terms in over 7000 COVID-19 News Article Titles from CBC News"),
                                   sidebarLayout(
                                       sliderInput("freq",
                                                   "Minimum Frequency:",
                                                   min = 1,  max = 600, value = 25),
                                       sliderInput("max",
                                                   "Maximum Number of Words:",
                                                   min = 10,  max = 500,  value = 100)
                                   ),
                                   mainPanel(plotOutput("plot", width = "1000px", height="800px"), 
                                   ),
                          ),
                          # Page for bigram network graph
                          tabPanel("Word Associations",
                                   titlePanel("Network of Bigrams of News Article Titles From CBC News"),
                                   plotOutput("bigramNetworkPlot", width="1000px", height="700px")
                          )
               )
        )
      
)
