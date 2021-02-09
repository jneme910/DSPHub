library(readr)
library(ggplot2)
## Read in model output
mod <- read_rds('logitMod.rds')

## Inputs
soc <- 2
text <- "T2"
subo <- "S3"
matc <- 20
mapmm <- 300

## Lookups
if(mod$Transform=="logit") soc <- qlogis(soc/100)
grp <- mod$Groups$ID[which(mod$Groups$Texture==text & mod$Groups$Suborder==subo)]
xint <- as.numeric(mod$GroupXmat[grp,])

## Make Predictions
  ## Note that this creates a posterior distribution of predicitons...one for each iteration of the model fit
xt <- c(xint, matc, mapmm)
mu <- c(mod$Beta%*%xt)
sig <- sqrt(mod$Variance[,grp])

## Make plot and output
steps <- seq(min(mu) - 4*max(sig), max(mu) + 4*max(sig), length.out = 100)
df1 <- apply(cbind(mu, sig), 1, function(x) pnorm(steps, mean=x[1], sd=x[2])) ## This is the CDF evaluated at plot locations
df2 <- data.frame(x=steps, mean=apply(df1,1,mean),
                       p.025= apply(df1, 1, quantile, probs=0.025),
                       p.975= apply(df1, 1, quantile, probs=0.975))
inpCDF <- apply(cbind(mu, sig), 1, function(x) pnorm(soc, mean=x[1], sd=x[2])) ## This is the CDF evaluated for input data
outTab <- data.frame("2.5%"=quantile(inpCDF, probs=0.025),
                          "Mean"=mean(inpCDF),
                          "97.5%"=quantile(inpCDF, probs=0.975), check.names = F)
plot1 <- ggplot(df2, aes(x=100*plogis(x)))+ 
      geom_ribbon(alpha=0.5, fill="green", color="green", size=0.1, aes(ymin=p.025, ymax=p.975))+
      geom_line(color="red", aes(y=mean))+
      ylab("Score")+
      geom_vline(linetype='dashed', aes(xintercept=plogis(soc)*100))+
      ggtitle("SOC score curve with 95% Credible Interval")+
      xlim(c(-1,11))+
      xlab("SOC (%)")

