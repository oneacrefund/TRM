#' Quantile regressions of Maize yield responses to fertilizer applications
#' Malawi LREP response trial data (courtesy of LREP)
#' LREP data documentation at: https://www.dropbox.com/s/4qbxnz4mdl92pdv/Malawi%20area-specific%20fertilizer%20recs%20report.pdf?dl=0
#' M. Walsh, December 2015

# Required packages
# install.packages(c("downloader","quantreg")), dependencies=TRUE)
require(downloader)
require(quantreg)

# Data setup --------------------------------------------------------------
# Create a "Data" folder in your current working directory
dir.create("MW_data", showWarnings=F)
setwd("./MW_data")

# download LREP fertilizer response data
download("https://www.dropbox.com/s/i4dby04fl9j042a/MW_fert_trials.zip?dl=0", "MW_fert_trials.zip", mode="wb")
unzip("MW_fert_trials.zip", overwrite=T)
sites <- read.table("Location.csv", header=T, sep=",")
trial <- read.table("Trial.csv", header=T, sep=",")
mresp <- merge(sites, trial, by="LID")
mresp <- mresp[order(mresp$Yt),] ## order dataframe based on treated yield (Yt)
mresp$Year <- mresp$Year-1996

# Exploratory plots -------------------------------------------------------
# ECDF plot
trt1 <- subset(mresp, NPS==1 & Urea==1, select=c(Yt,Yc)) 
trt2 <- subset(mresp, NPS==2 & Urea==2, select=c(Yt,Yc)) 
trt3 <- subset(mresp, NPS==2 & Urea==3, select=c(Yt,Yc))
plot(ecdf(mresp$Yc), main="", xlab="Maize yield (kg/ha)", ylab="Cum. proportion of observations", xlim=c(-50, 8050), verticals=T, lty=1, lwd=2, col="red", do.points=F)
abline(0.5,0, lty=2, col="grey")
plot(ecdf(trt1$Yt), add=T, verticals=T, lty=1, lwd=1, col="blue", do.points=F)
plot(ecdf(trt2$Yt), add=T, verticals=T, lty=1, lwd=1, col="blue", do.points=F)
plot(ecdf(trt3$Yt), add=T, verticals=T, lty=1, lwd=1, col="blue", do.points=F)

# Treatment/Control quantile plot
plot(Yt ~ Yc, data = mresp, cex= 0.7, col = "grey", 
     xlim = c(-200, 8200), ylim = c(-200, 8200),
     xlab = "Unfertilized maize yield (kg/ha)", ylab = "Fertilized maize yield (kg/ha)")
abline(c(0,1), col = "red", lwd = 2) ## 1:1 line
AQ <- rq(log(Yt)~log(Yc), tau=c(0.05,0.25,0.5,0.75,0.95), data=mresp)
curve(exp(AQ$coefficients[1])*x^AQ$coefficients[2], add=T, from=0, to=8000, col="blue", lwd=1)
curve(exp(AQ$coefficients[3])*x^AQ$coefficients[4], add=T, from=0, to=8000, col="blue", lty=2)
curve(exp(AQ$coefficients[5])*x^AQ$coefficients[6], add=T, from=0, to=8000, col="blue", lwd=2)
curve(exp(AQ$coefficients[7])*x^AQ$coefficients[8], add=T, from=0, to=8000, col="blue", lty=2)
curve(exp(AQ$coefficients[9])*x^AQ$coefficients[10], add=T, from=0, to=8000, col="blue", lwd=1)

# Quantile regression -----------------------------------------------------
AQ.rq <- rq(log(Yt)~log(Yc)+NPS+Urea, tau = seq(0.05, 0.95, by = 0.05), data = mresp)
plot(summary(AQ.rq), main = c("Intercept","Unfertilized yield","NPS","Urea")) ## Coefficient plots

# Identify trials in the lowest conditional quartile ----------------------
# Linear model
Q25.rq <- rq(log(Yt)~log(Yc)+NPS+Urea, tau = 0.25, data = mresp)
mresp$Q25 <- ifelse(exp(predict(Q25.rq, mresp)) > mresp$Yt, 1, 0)
prop.table(table(mresp$Q25))
