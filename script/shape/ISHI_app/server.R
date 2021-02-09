library(shiny)
library(ggplot2)
library(readr)

mod <- read_rds("logitMod.rds")

function(input, output) {
  vals <- reactiveValues()
  observe({
    req(input$text, input$subo, input$matc, input$mapmm, input$soc)
    vals$soc <- input$soc
    if(mod$Transform=="log") vals$soc <- log(input$soc)
    if(mod$Transform=="logit") vals$soc <- qlogis(input$soc/100)
    vals$grp <- mod$Groups$ID[which(mod$Groups$Texture==input$text & mod$Groups$Suborder==input$subo)]
    vals$xint <- as.numeric(mod$GroupXmat[vals$grp,])
    vals$xt <- c(vals$xint, input$matc, input$mapmm)
    vals$mu <- c(mod$Beta%*%vals$xt)
    vals$sig <- sqrt(mod$Variance[,vals$grp])
    vals$steps <- seq(min(vals$mu) - 4*max(vals$sig), max(vals$mu) + 4*max(vals$sig), length.out = 100)
    vals$df1 <- apply(cbind(vals$mu, vals$sig), 1, function(x) pnorm(vals$steps, mean=x[1], sd=x[2]))
    vals$df2 <- data.frame(x=vals$steps, mean=apply(vals$df1,1,mean),
                           p.025= apply(vals$df1, 1, quantile, probs=0.025),
                           p.975= apply(vals$df1, 1, quantile, probs=0.975))
    vals$inpCDF <- apply(cbind(vals$mu, vals$sig), 1, function(x) pnorm(vals$soc, mean=x[1], sd=x[2]))
    vals$outTab <- data.frame("2.5%"=quantile(vals$inpCDF, probs=0.025),
                              "Mean"=mean(vals$inpCDF),
                              "97.5%"=quantile(vals$inpCDF, probs=0.975), check.names = F)
    output$cdf <- renderPlot(
      if(mod$Transform=="log"){
        return(
          ggplot(vals$df2, aes(x=exp(x)))+ 
            geom_ribbon(alpha=0.5, fill="green", color="green", size=0.1, aes(ymin=p.025, ymax=p.975))+
            geom_line(color="red", aes(y=mean))+
            ylab("Score")+
            geom_vline(linetype='dashed', aes(xintercept=input$soc))+
            ggtitle("SOC score curve with 95% Credible Interval")+
            xlim(c(-1,11))+
            xlab("SOC (%)")
        )
      }
      else{
        if(mod$Transform=="logit"){
          return(
            ggplot(vals$df2, aes(x=100*plogis(x)))+ 
              geom_ribbon(alpha=0.5, fill="green", color="green", size=0.1, aes(ymin=p.025, ymax=p.975))+
              geom_line(color="red", aes(y=mean))+
              ylab("Score")+
              geom_vline(linetype='dashed', aes(xintercept=input$soc))+
              ggtitle("SOC score curve with 95% Credible Interval")+
              xlim(c(-1,11))+
              xlab("SOC (%)")
          )
        }
        else{
          return(
            ggplot(vals$df2, aes(x=x))+ 
              geom_ribbon(alpha=0.5, fill="green", color="green", size=0.1, aes(ymin=p.025, ymax=p.975))+
              geom_line(color="red", aes(y=mean))+
              ylab("Score")+
              geom_vline(linetype='dashed', aes(xintercept=input$soc))+
              ggtitle("SOC score curve with 95% Credible Interval")+
              xlab("SOC (%)")
          )
        }
      }
    )
    output$tab <- renderTable(vals$outTab, align='c')
  })
  
}