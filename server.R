library(shiny)

server <- function(input, output) {
    
    # render country time-series visualizations
    output$covidgraph <- renderDygraph({
        covid19$dateRep <- as.Date(covid19$dateRep, format = "%m/%d/%Y")
        countryByDates <- covid19 %>% filter(country == input$Country) %>% filter(dateRep >= input$dates[1], dateRep <= input$dates[2])
        filtered_cases <- countryByDates %>% select(cases)
        filtered_deaths <- countryByDates %>% select(deaths)
        cases <- xts(filtered_cases, order.by=countryByDates$dateRep)
        deaths <- xts(filtered_deaths, order.by=countryByDates$dateRep)
        covid19Tracker <- cbind(cases, deaths)
        dygraph(covid19Tracker, main="COVID-19 Reported Cases and Deaths") 
    })
    
    
    
    # Country selection drop-down for the time-series visualization
    output$casesDeaths <- renderUI({
        selectInput("Country", 
                    "country",
                    choices=unique(covid19$country))
    })
    
    
    # Generate word cloud 
    output$plot <- renderPlot({
        wordcloud(words=names(word_freq), freq=word_freq,
                  min.freq = input$freq, max.words=input$max,scale=c(1,3),
                  colors=brewer.pal(8, "Dark2"))
    })
    

    # render network graph of bigrams 
    output$bigramNetworkPlot <- renderPlot({
        set.seed(2017)
        a <- grid::arrow(angle=40, type = "closed", length = unit(.23, "inches"))
        ggraph(bigram_graph, layout = "fr") +
            geom_edge_link(aes(edge_alpha = n), show.legend = FALSE, arrow = a) +
            geom_node_point(color="royalblue", size=4) +
            geom_node_text(aes(label = name), size=3, fontface="bold", vjust = 1, hjust = 1) 
    })
    
    
    
    
    # Render Choropleth Leaflet Maps based on selection from ui radio buttons
    output$covidMap <- renderLeaflet({
        # choropleth map of total deaths 
        if(input$summaryStats=='Total Deaths'){
            covidMappingDeaths<- geo_join(countries, totalDeaths, "ADMIN", "Country")
            bins<- c(0, 500, 1000, 3000, 5000, 10000, 15000, 30000, 45000, 75000, 90000, 140000, 300000, 500000 )
            pal <- colorBin("YlGnBu", domain = covidMappingDeaths$totalDeaths, bins=bins)
            labels <- sprintf("<strong>%s</strong><br/>Total Deaths: %g", covidMappingDeaths$ADMIN, covidMappingDeaths$totalDeaths) %>% lapply(htmltools::HTML)
            leaflet(covidMappingDeaths) %>% 
                addTiles() %>%
                setView(-71.0382679, 42.3489054, zoom=3) %>% 
                setMaxBounds(-160,-180, 160, 180) %>%
                addPolygons( 
                    fillColor = ~pal(covidMappingDeaths$totalDeaths), 
                    weight = 2,
                    opacity = 1, 
                    color = "white",
                    dashArray = "3",
                    fillOpacity = 3,
                    smoothFactor = 0.2,
                    highlight = highlightOptions(
                        weight = 8,
                        color = "#666",
                        dashArray = "",
                        fillOpacity = 0.7,
                        bringToFront = TRUE),
                    label = labels,
                    labelOptions = labelOptions(style=list('box-shadow' = '3px 3px rgba(0,0,0,0.25)'), 'textsize'='15px')) %>%
                leaflet::addLegend(pal = pal, 
                                   values = covidMappingDeaths$totalDeaths, 
                                   position = "bottomright", 
                                   title = "Total Deaths")
        }
        # choropleth map of total cases
        else if(input$summaryStats == "Total Cases"){
            covidMapping<- geo_join(countries, totalCases, "ADMIN", "Country")
            bins<- c(0, 500, 2000, 10000, 50000, 100000, 200000, 500000, 1000000, 2000000, 5000000, 8000000, 10000000, 15000000, 20000000)
            pal <- colorBin("RdPu", domain = covidMapping$totalCases, bins = bins)
            labels <- sprintf("<strong>%s</strong><br/>Total Cases: %g", covidMapping$ADMIN, covidMapping$totalCases) %>% lapply(htmltools::HTML)
            leaflet(covidMapping) %>% 
                addTiles() %>%
                setView(-71.0382679, 42.3489054, zoom=3) %>% 
                setMaxBounds(-160,-180, 160, 180) %>%
                addPolygons( 
                    fillColor = ~pal(covidMapping$totalCases), 
                    weight = 2,
                    opacity = 1, 
                    color = "white",
                    dashArray = "3",
                    fillOpacity = 0.7,
                    smoothFactor = 0.2,
                    highlight = highlightOptions(
                        weight = 5,
                        color = "#666",
                        dashArray = "",
                        fillOpacity = 0.7,
                        bringToFront = TRUE),
                    label = labels,
                    labelOptions = labelOptions(style=list('box-shadow' = '3px 3px rgba(0,0,0,0.25)'), 'textsize'='15px')) %>%
                leaflet::addLegend(pal = pal, 
                                   values = covidMapping$totalCases, 
                                   position = "bottomright", 
                                   title = "Total Cases")
        }
    })
}   

