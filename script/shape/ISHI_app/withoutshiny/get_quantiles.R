library(readr)
library(ggplot2)
## Read in model output
mod <- read_rds('logitMod.rds')

## Inputs
quantile <- .9
text <- "T2"
subo <- "S3"
matc <- 20
mapmm <- 300

## Lookups
grp <- mod$Groups$ID[which(mod$Groups$Texture==text & mod$Groups$Suborder==subo)]
xint <- as.numeric(mod$GroupXmat[grp,])

## Make Predictions
## Note that this creates a posterior distribution of predicitons...one for each iteration of the model fit
xt <- c(xint, matc, mapmm)
mu <- c(mod$Beta%*%xt)
sig <- sqrt(mod$Variance[,grp])

## Generate SOC quantile

## This is the quantile function evaluated for input data
inpQuants <- apply(cbind(mu, sig), 1, function(x) 100*plogis(qnorm(quantile, mean=x[1], sd=x[2]))) 

outTab <- data.frame("Lower_Bound"=quantile(inpQuants, probs=0.025),
                     "Quantile_Estimate"=mean(inpQuants),
                     "Upper_Bound"=quantile(inpQuants, probs=0.975), check.names = F)

