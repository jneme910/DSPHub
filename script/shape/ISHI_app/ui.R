library(shiny)
library(ggplot2)
library(readr)

mod <- read_rds("logitMod.rds")

inactivity <- "function idleTimer() {
  var t = setTimeout(logout, 60000);
  window.onmousemove = resetTimer; // catches mouse movements
  window.onmousedown = resetTimer; // catches mouse movements
  window.onclick = resetTimer;     // catches mouse clicks
  window.onscroll = resetTimer;    // catches scrolling
  window.onkeypress = resetTimer;  //catches keyboard actions

  function logout() {
    window.close();  //close the window
  }

  function resetTimer() {
    clearTimeout(t);
    t = setTimeout(logout, 60000);  // time is in milliseconds (1000 is 1 second)
  }
}
idleTimer();"

fluidPage(
  tags$script(inactivity),
  tags$h1("Soil Health Dashboard"),
  sidebarLayout(
    sidebarPanel(tags$h2("Soil Properties"),
                 selectInput("text", "Texture", sort(unique(mod$Groups$Texture))),
                 selectInput("subo", "Suborder", sort(unique(mod$Groups$Suborder))),
                 numericInput("matc", "Temperature (degrees C)", 11),
                 numericInput("mapmm", "Precipitation (mm)", 851, min=0),
                 numericInput("soc", "SOC (%)", 1.8, min=0, max=100)),
    mainPanel(
      fluidRow(
        column(12, align='center',
               tags$h4("SOC ISHI score with credible interval"), 
               tableOutput("tab")
        )
      ), 
      plotOutput("cdf"))
  )
)