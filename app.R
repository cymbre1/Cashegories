# Load packages ----------------------------------------------------------------
library(shiny)
library(tidyverse)

# Load data --------------------------------------------------------------------

bankinfo <- read_csv("data.csv")
bankinfo <- bankinfo %>% 
  mutate(type = case_when(
    str_detect(Description, "^WITHDRAWAL")~"Withdrawal",
    str_detect(Description, "^Withdrawal")~"Withdrawal",
    str_detect(Description, "^DEPOSIT")~"Deposit",
    str_detect(Description, "^BILLPAYMENT")~"BillPayment",
    TRUE~"UNKNOWN"
  ))

bankinfo <- bankinfo %>% 
  mutate(purchaser = case_when(
    str_detect(Description, "#1")~"Cymbre",
    str_detect(Description, "#2")~"Michael",
    TRUE~"None"
  ))

bankinfo <- bankinfo %>% 
  mutate(category = case_when(
    str_detect(Description, "MEIJER")~"BILLS",
    str_detect(Description, "HORROCKS MARKET")~"BILLS",
    str_detect(Description, "Bill Payment")~"BILLS",
    str_detect(Description, "TOMMYS-EXPRESS")~"BILLS",
    str_detect(Description, "FAMILY FARE")~"BILLS",
    str_detect(Description, "DTE Energy")~"UTILITIES",
    str_detect(Description, "GLAD TIDINGS")~"BILLS",
    str_detect(Description, "CHASE")~"BILLS",
    str_detect(Description, "SHELL OIL")~"BILLS",
    str_detect(Description, "VRIESLAND COUNTRY STORE")~"BILLS",
    str_detect(Description, "Monarch")~"RENT",
    str_detect(Description, "Spotify USA")~"BILLS",
    str_detect(Description, "EAST 44TH ST AGO")~"BILLS",
    str_detect(Description, "Audible*")~"BILLS",
    str_detect(Description, "GRAND RAPIDS FIRST")~"DONATIONS",
    str_detect(Description, "GLAD TIDINGS")~"DONATIONS",
    str_detect(Description, "HOLY TRINITY")~"DONATIONS",
    str_detect(Description, "WORLD VISION")~"DONATIONS",
    str_detect(Description, "DRIP")~"CYMBRE",
    str_detect(Description, "GOOGLE *Audible")~"CYMBRE",
    str_detect(Description, "DEPOSIT")~"INCOME",
    TRUE~"UNKNOWN"
  ))

# Define UI --------------------------------------------------------------------

ui <- fluidPage(
  sidebarLayout(
    
    sidebarPanel(
      HTML(paste0("Hello Cymbre!")),
    ),
    mainPanel(
      plotOutput(outputId = "scatterplot")
    )
  )
)

# Define server ----------------------------------------------------------------

server <- function(input, output, session) {
  output$scatterplot <- renderPlot({
    ggplot(data = bankinfo, aes_string(x = bankinfo$category, y = bankinfo$Amount )) +
      geom_col()
  })
}
  
# Create a Shiny app object ----------------------------------------------------

shinyApp(ui = ui, server = server)
