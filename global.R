library(dplyr)
library(plyr)
library(utils)
library(stringr)
library(tm)
library(tidytext)
library(wordcloud)
library(ggplot2)
library(shiny)
library(stringi)
library(leaflet)
library(shinyWidgets)
library(dygraphs)
library(tigris)
library(xts)
library(rmarkdown)
library(syuzhet)
library(tibble)
library(tidyr)
library(igraph)
library(ggraph)
library(sf)

# read in data sets
covid19 <- covid19 <- read.csv("~/COVID-19-Tracker/datasets/covid19.csv", na.strings = "", fileEncoding = "UTF-8-BOM")
covid19<-plyr::rename(covid19, replace=c(countriesAndTerritories="country", continentExp="continent"))
countries <- geojsonio::geojson_read("~/COVID-19-Tracker/datasets/countries.geojson", what = "sp")
covid_news <- read.csv("~/COVID-19-Tracker/datasets/covid19_news.csv")


#Convert country and continent to factors
covid19$continent <- factor(covid19$continent)
covid19$country <- factor(covid19$country)
covid19$country <- gsub("_", " ", covid19$country, fixed=TRUE)


# Calculate total number of coronavirus cases
totalCases <- aggregate(x = covid19$cases,               
                        by = list(covid19$country),              
                        FUN = sum)
colnames(totalCases) <- c("Country", "totalCases")



# Calculate total number of coronavirus deaths
totalDeaths <- aggregate(x = covid19$deaths,            
                         by = list(covid19$country),              
                         FUN = sum) 
colnames(totalDeaths) <- c("Country", "totalDeaths")


# create a simple corpus of 6788 documents(news article titles)
news_titles_corpus <-  Corpus(VectorSource(covid_news$title))
tm_map(news_titles_corpus, function(x) iconv(enc2utf8(x), sub = "byte"))



# corpus pre-processing steps to clean text
clean_corpus <- function(corpus, removal_words_vector){
  corpus <- tm_map(corpus, tolower)
  corpus <- tm_map(corpus, removeWords, c(stopwords("en")))
  corpus <- tm_map(corpus, removeWords, removal_words_vector)
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus, removePunctuation)
  cleaned_corpus <- tm_map(corpus, stripWhitespace)
  return(cleaned_corpus)
}

# create a vector of words relating to Canada to be removed from the text. 
words_to_remove <- c("canadian", "canada", "ottawa", "quebec", "Vancouver", "scotia", "winnipeg", "canadians", "alberta", "toronto", "calgary", "coronavirus", "covid", "manitoba", "waterloo",  "says", "ontario")
news_titles_corpus <- clean_corpus(news_titles_corpus, words_to_remove)


# Create a document-term matrix where each document (new article title) is represented as a row and every term is a column. 
# Determines the frequency of words in each document
create_documentTermMatrix <- function(corpus){
  document_term_matrix <- DocumentTermMatrix(corpus)
  return(document_term_matrix)
}
covid_dtm <- create_documentTermMatrix(news_titles_corpus) 

#convert the corpus into a Term Document Matrix, a 2-dimensional matrix where rows represent the terms, and the columns
# represent the documents. Each cell in the matrix contains the frequency of a term i in a document j. 
covid_tdm <- as.matrix(TermDocumentMatrix(news_titles_corpus))
word_freq <- sort(rowSums(covid_tdm), decreasing=TRUE)
#Tidying the document-term matrix to use with tidytext, dplyr, and ggplot packages
covid_dtm_tidy <- tidy(covid_dtm)



generate_network_graph_bigrams <- function(tidy_DTM, n){
  bigrams <- tidy_DTM  %>%   unnest_tokens(bigram, term, token = "ngrams", n = 2)
  separated_bigrams <- bigrams %>% separate(bigram, c("word1", "word2"), sep = " ")
  cleaned_bigrams <- na.omit(separated_bigrams)
  bigram_count <- cleaned_bigrams %>% dplyr::count(word1, word2, sort=TRUE)
  bigram_graph <- bigram_count %>% filter(n > 8)  %>% graph_from_data_frame()
  return(bigram_graph)
}
bigram_graph <- generate_network_graph_bigrams(covid_dtm_tidy)
