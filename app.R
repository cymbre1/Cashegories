# Load packages ----------------------------------------------------------------
library(shiny)
library(shinyWidgets)
library(tidyverse)
library(plotrix)

# Load data --------------------------------------------------------------------
# Read in Data
bankinfo <- read_csv("data.csv")
budget <- read_csv("cymbres-budget.csv")
output <- read_csv("output.csv")

# Create a column that tells whether the entry was a deposit or a withdrawal.
bankinfo <- bankinfo %>% 
  mutate(type = case_when(
    str_detect(Description, "^WITHDRAWAL")~"Withdrawal",
    str_detect(Description, "^Withdrawal")~"Withdrawal",
    str_detect(Description, "^DEPOSIT")~"Deposit",
    str_detect(Description, "^BILLPAYMENT")~"BillPayment",
    TRUE~"UNKNOWN"
  ))

# Determine based on the card number who made the purchase
bankinfo <- bankinfo %>% 
  mutate(purchaser = case_when(
    str_detect(Description, "#1")~"Cymbre",
    str_detect(Description, "#2")~"Michael",
    TRUE~"None"
  ))

# Detect different keywords in the description in order to categorize it.
bankinfo <- bankinfo %>% 
  mutate(category = case_when(
    str_detect(Description, "MEIJER")~"GROCERIES",
    str_detect(Description, "HORROCKS MARKET")~"GROCERIES",
    str_detect(Description, "TOMMYS EXPRESS")~"BILLS",
    str_detect(Description, "TOMMYS-EXPRESS")~"BILLS",
    str_detect(Description, "STATE FARM")~"INSURANCE",
    str_detect(Description, "FAMILY FARE")~"GAS",
    str_detect(Description, "DTE Energy")~"UTILITIES",
    str_detect(Description, "CONSUMERS")~"UTILITIES",
    str_detect(Description, "COMCAST")~"UTILITIES",
    str_detect(Description, "VESTA")~"BILLS",
    str_detect(Description, "Disney Mobile")~"BILLS",
    str_detect(Description, "Monarch")~"RENT",
    str_detect(Description, "GLAD TIDINGS")~"DONATIONS",
    str_detect(Description, "HOLY TRINITY")~"DONATIONS",
    str_detect(Description, "GRAND RAPIDS FIRST")~"DONATIONS",
    str_detect(Description, "WORLD VISION")~"DONATIONS",
    str_detect(Description, "CHASE")~"BILLS",
    str_detect(Description, "SHELL OIL")~"GAS",
    str_detect(Description, "VRIESLAND COUNTRY STORE")~"GAS",
    str_detect(Description, "Spotify USA")~"BILLS",
    str_detect(Description, "EAST 44TH ST AGO")~"GAS",
    str_detect(Description, "Speedway")~"GAS",
    str_detect(Description, "Audible*")~"BILLS",
    str_detect(Description, "Amazon Prime")~"BILLS",
    str_detect(Description, "DRIP")~"CYMBRE",
    str_detect(Description, "GOOGLE *Audible")~"CYMBRE",
    str_detect(Description, "ZEELAND")~"CYMBRE",
    str_detect(Description, "HUDSONVILLE")~"CYMBRE",
    str_detect(Description, "DEPOSIT")~"INCOME",
    str_detect(Description, "BIGGBY")~"BIGGBY",
    str_detect(Description, "RED ROBIN")~"DATES",
    str_detect(Description, "Brewing")~"DATES",
    str_detect(Description, "BREWING")~"DATES",
    str_detect(Description, "CELEBRATION CINEMA")~"DATES",
    str_detect(Description, "VILLAGE INN")~"DATES",
    str_detect(Description, "^DEPOSIT")~"DEPOSIT",
    str_detect(Description, "^Deposit")~"DEPOSIT",
    TRUE~"UNKNOWN"
  )) %>% 
  # Change the amount column to be numeric
  mutate(Amount = parse_number(Amount)) %>% 
  # Change the balance column to be numeric
  mutate(Balance = parse_number(Balance))

# Find the current balance of the account by finding the in the Balance column
accountBalance <- bankinfo %>% 
    summarise(Last_value_sales = last(Balance))

# Find the total amount of money that was budgeted for a month by summing all of 
# the values in the Budget column of the Budget csv
totalBudgetedAmount <- budget %>% 
    summarize(total = sum(Budget))

# Determine how much in total was spent by summing the total amount that was
# withdrawn from the account
totalSpending <- bankinfo %>% 
    filter(type == "Withdrawal") %>% 
    summarize(total = sum(Amount))

# Determine how much money Cymbre has left by subtracting the total amount that
# she has spent and subtracting the amount budgeted for her from that.
cymbreRemaining <- bankinfo %>% 
    filter(category=="CYMBRE") 
    #(100 - sum(cymbreSpentRows$Amount))

michaelRemaining <- bankinfo %>% 
    filter(category=="MICHAEL")
    #(100 - sum(michaelSpentRows$Amount))

# Generate the output for the summary statistics to be displayed in a table in 
# the sidebar panel.
output <- output %>% 
  mutate(Output = case_when(
    str_detect(Title, "Account Balance")~"100",
    str_detect(Title, "Total Budgeted")~"500",
    str_detect(Title, "Total Spent")~"300",
    str_detect(Title, "Cymbre Fun")~"200",
    str_detect(Title, "Michael Fun")~"50",
    TRUE~"DONT USE ME"
  ))

# Define UI --------------------------------------------------------------------

ui <- fluidPage(
  titlePanel(h1("Cashegories", align="center", style = "color:#F58216"),
             p(strong("bold font "), em("italic font"),)),
  setBackgroundColor(
    color="#3D4849",
    gradient = c("linear", "radial"),
    direction = c("bottom", "top", "right", "left"),
    shinydashboard = FALSE
  ),
  sidebarLayout(
    sidebarPanel(
      # Categories options menu
      selectInput(inputId = "categoryToCategorize",
                  label = "Category:",
                  choices = unique(budget$Category),
                ),
      # Uncategorized entries menu
      selectInput(inputId = "entryToCategorize",
                  label = "Purchases to Categorize:",
                  choices = bankinfo %>% 
                    filter(category == "UNKNOWN") %>% 
                    select(Description),
                ),
      # Button that when pressed will categorized the data in the menus
      actionButton("Hello", "Categorize!", style="background-color:#F58216; border-color:#3D4849"),
      tableOutput('table')
    ),
    # Panel with all of the charts
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
      # Groups the dataset by the category
      group_by(category) %>% 
      # Summarizes the total in the amount column for each category
      summarize(total = sum(Amount)) %>%
      # Filters out the income category
      filter(category != "INCOME" ) %>%
      # Filter out the deposit category so that there is only money spent in 
      # the graph
      filter(category != "DEPOSIT") %>% 
    ggplot(aes(x = category, y = total)) +
      geom_col(position="dodge", fill="#F58216") +
      # Displays the total money spent for each category over the corresponding
      # column
      geom_text(aes(label=total), position=position_dodge(width=0.9), vjust=-0.25)
  })
  
  output$savingsovertime <- renderPlot({
    bankinfo %>% 
      # This will make a line chart of the amount of money in the account over
      # time. The as.Date function will interpret the Date column as a date.
      # The "%m/%d/%y" will tell the as.Date function the format in which the 
      # date in my dataset is formatted.
      ggplot(aes(x = as.Date(Date,"%m/%d/%y"), y = Balance)) +
        geom_line(color = "orange")
  })
  
  output$table <- renderTable(output)
}
  
# Create a Shiny app object ----------------------------------------------------

shinyApp(ui = ui, server = server)
