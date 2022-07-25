# Load packages ----------------------------------------------------------------
library(shiny)
library(tidyverse)

# Load data --------------------------------------------------------------------

bankinfo <- read_csv("data.csv")
budget <- read_csv("cymbres-budget.csv")
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
    str_detect(Description, "MEIJER")~"GROCERIES",
    str_detect(Description, "HORROCKS MARKET")~"GROCERIES",
    str_detect(Description, "Bill Payment")~"BILLS",
    str_detect(Description, "TOMMYS-EXPRESS")~"BILLS",
    str_detect(Description, "FAMILY FARE")~"GROCERIES",
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
  )) %>% 
  mutate(Amount = parse_number(Amount)) %>% 
  mutate(Balance = parse_number(Balance))


# Define UI --------------------------------------------------------------------

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      HTML(paste0("Account Balance: $")),
      bankinfo %>% 
        summarise(Last_value_sales = last(Balance)),
      HTML(paste0("Total Spending: $")),
      bankinfo %>% 
        filter(type == "Withdrawal") %>% 
        summarize(total = sum(Amount))
    ),
    mainPanel(
      plotOutput(outputId = "barchart"),
      plotOutput(outputId = "savingsovertime")
    )
  )
)

# Define server ----------------------------------------------------------------

server <- function(input, output, session) {
  output$barchart <- renderPlot({
    bankinfo %>% 
      group_by(category) %>% 
      summarize(total = sum(Amount)) %>%
      filter(category != "INCOME") %>% 
    ggplot(aes(x = category, y = total, label = scales::percent(Amount))) +
      geom_col()
      geom_text(stat='count', aes(label=..count..), vjust=-1)
  })
  output$savingsovertime <- renderPlot({
    bankinfo %>% 
      ggplot(aes(x = as.Date(Date,"%m/%d/%y"), y = Balance)) +
        geom_line(color = "orange")
  })
}
  
# Create a Shiny app object ----------------------------------------------------

shinyApp(ui = ui, server = server)
