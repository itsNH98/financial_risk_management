library(tidyr)
library(dplyr)
library(xts)
library(tidyquant)
library(readr)
library(frenchdata)


setwd('~/Documents/Work/research/main/investing/risk_management/')

# ------------------------------
#|                             |
#|      1. Data Section        |
#|                             |
# ------------------------------



# 1.1 Returns Data  ------------------------

# Read the CSV file
returns_df <- read.csv('./data/returns.csv')
returns_df$Ticker <- as.character(returns_df$Ticker)
returns_df$DlyCalDt <- as.Date(returns_df$DlyCalDt)

# Calculate the mean of 'DlyRet' for each unique combination of 'DlyCalDt' and 'Ticker'
df_aggregated <- returns_df %>%
  group_by(DlyCalDt, Ticker) %>%
  summarize(mean_DlyRet = mean(DlyRet))

# Use pivot_wider() to reshape the data
pivoted_returns <- pivot_wider(df_aggregated, names_from = Ticker, values_from = mean_DlyRet)
pivoted_returns$DlyCalDt = as.Date(pivoted_returns$DlyCalDt)

# Log Returns 
pivoted_returns[, -1] <- log(1 + pivoted_returns[, -1])

# Convert 'Date' column to a proper date format
# daily_logrets$Date <- as.Date(pivoted_returns$DlyCalDt)
daily_returns <- as.xts(pivoted_returns[, -1],order.by=as.Date(pivoted_returns$DlyCalDt))
weekly_returns <- apply.weekly(daily_returns, colSums)

# 1.2 FF Factors Data ----------------------------------

FF <- download_french_data("Fama/French 3 Factors [Daily]")$subsets$data[[1]]
MOM <- download_french_data("Momentum Factor (Mom) [Daily]")$subsets$data[[1]]

# Set appropriate column names
colnames(FF) <- c("Date", "MktMinusRF", "SMB", "HML", "RF")
colnames(MOM) <- c("Date", "Mom")

# Combine the FF and MOM tables
factors <- merge(FF, MOM, by = "Date")

# Slice by Date
factors$Date <- as.Date(as.character(factors$Date), format = "%Y%m%d")
factors <- factors[factors$Date >= as.Date("1963-07-05") & factors$Date <= as.Date("2019-12-31"), ]
factors <- subset(factors, select = -RF)

factors[, -1] = factors[, -1] / 100

# Log and Resampling
factors[, -1] <- log(1 + factors[, -1])

# Convert 'Date' column to a proper date format
factors_xts <- as.xts(factors[, -1],order.by=as.Date(factors$Date))
weekly_factors <- apply.weekly(factors_xts, colSums)


# 1.3 Descriptive Statistics -------------------------------

summary_returns <- summary(weekly_returns)
summary_factors <- summary(weekly_factors)


# 1.4 EW Stock Portfolios ---------------------------------

num_stocks <- length(pivoted_returns[, -1])
weights <- rep(1/num_stocks, num_stocks)

ew <- data.frame(EW = c(rowMeans(pivoted_returns[, -1], na.rm = T)))
rownames(ew) <- pivoted_returns$DlyCalDt

log_ew <-  log(1 + ew)

ew_xts <- as.xts(log_ew,order.by=as.Date(rownames(log_ew)))
weekly_log_ew <- apply.weekly(ew_xts, colSums)


# ------------------------------
#|                             |
#|2. Univariate Models Section |
#|                             |
# ------------------------------

"
Models:
(1) AR(3)-NGARCH(1,1)-Skewt
(2) AR(3)-NGARCH(1,1)-Normal
(3) AR(3)-NGARCH(1,1)-FHS
"

library(rugarch)
library(quarks)
library(cvar)

# 2.1 Fixed distribution models -----------------------------

# AR(3)-NGARCH(1,1)-Normal specification
mod_ar_ngarch_normal <- ugarchspec(mean.model = list(armaOrder=c(3,0)), 
                            variance.model = list(model= 'fGARCH', submodel='NGARCH', garchOrder = c(1, 1)),
                            distribution.model = 'norm')

mod_fitting_ar_ngarch_normal <-  ugarchfit(data = weekly_log_ew, spec = mod_ar_ngarch_normal, out.sample = 0)

# AR(3)-NGARCH(1,1)-Skewt specification
mod_ar_ngarch_skewt <- ugarchspec(mean.model = list(armaOrder=c(3,0)), 
                         variance.model = list(model= 'fGARCH', submodel='NGARCH', garchOrder = c(1, 1)),
                         distribution.model = 'sstd')

mod_fitting_ar_ngarch_skewt <-  ugarchfit(data = weekly_log_ew, spec = mod_ar_ngarch_skewt, out.sample = 0)

# Generate Rolling t+1 forecast
window_size = 52*20
step_size = 1

roll_normal <- ugarchroll(mod_ar_ngarch_normal, weekly_log_ew, refit.every = step_size, window.size = window_size)
roll_skewt <- ugarchroll(mod_ar_ngarch_skewt, weekly_log_ew, refit.every = step_size, window.size = window_size)

# t+1 VaRs
one_std_var_normal <- as.data.frame(roll_normal, which='VaR')[, 2]
two_std_var_normal <- as.data.frame(roll_normal, which='VaR')[, 1]

one_std_var_skewt <- as.data.frame(roll_skewt, which='VaR')[, 2]
two_std_var_normal <- as.data.frame(roll_skewt, which='VaR')[, 1]

# Test values
test_ew <- weekly_log_ew[(length(weekly_log_ew) - window_size + 1):length(weekly_log_ew)]


# 2.2 FHS equivalent -----------------------------
# 
# var_list <- list()
# 
# for (i in 1:(nrow(weekly_log_ew) - window_size)) {
#   start_idx <- i
#   end_idx <- start_idx + window_size - 1
# 
#   fhs_results_normal <- fhs(weekly_log_ew[start_idx:end_idx], p=0.95, model= "GARCH",
#                      mean.model = list(armaOrder=c(3,0)),
#                      variance.model = list(model= 'fGARCH', submodel='NGARCH', garchOrder = c(1, 1)),
#                      distribution.model = 'norm',
#                      nboot = 1000)
#   var_list <- c(var_list, fhs_results_normal$VaR)
# }

roll_fhs <- rollcast(x = weekly_log_ew, p=0.95, model = 'GARCH',
                mean.model = list(armaOrder=c(3,0)),
                variance.model = list(model= 'fGARCH', submodel='NGARCH', garchOrder = c(1, 1)),
                method = 'fhs', nwin=window_size, nout=100, nboot=1000)


# 2.3 Evaluation  -----------------------------

# Coverage tests Christoffersen (1998, 2001) for core models
one_std_cov <- VaRTest(0.05, test_ew, one_std_var, 0.05)
two_std_cov <- VaRTest(0.01, test_ew, two_std_var, 0.05)

# Duration tests (independence) Christoffersen & Pelletier (2004) for core models 
one_std_ind <-VaRDurTest(0.05, test_ew, one_std_var, 0.05)
two_std_ind <- VaRDurTest(0.01, test_ew, two_std_var, 0.05)

# FHS Full Evaluation
one_std_fhs <-cvgtest(roll_fhs, conflvl = 0.95)
one_std_fhs <-cvgtest(roll_fhs, conflvl = 0.95)

# Plot returns, VaR and exceedances
plot(roll_skewt, which=4, VaR.alpha = 0.05)
plot(roll_normal, which=4, VaR.alpha = 0.05)
plot(roll_fhs)



# ------------------------------
#|                             |
#|3.Multivariate Models Section|
#|                             |
# ------------------------------

"
Univariate Specification is given by the AR(3)-NGARCH(1, 1)-Skewt model 
Consideration of the Skewed-T copulas model of Demarta (2005)
Copula correlation matrix evolves through time, cDCC Aielli (2013)

Models:
(1) cDCC skewt
(2) cDCC normal
(3) cDCC t
(4, 5, 6) Constant correlation matrix of the preceding 
(7, 8) Marginals following a normal, dynamic and constant copulas 
"

library(rmgarch)

# 3.1 Coefficients set for Direct Projection ----------
merged_df <- cbind(weekly_log_ew ,weekly_factors)

lin_mod <- lm(EW ~ MktMinusRF + SMB + HML + Mom, data=merged_df)
lin_mod_coefs <- lin_mod$coefficients

weekly_factors_cnst <- weekly_factors
weekly_factors_cnst$constant <- 1
weekly_factors_cnst <- weekly_factors_cnst[, c(ncol(weekly_factors_cnst), 1:(ncol(weekly_factors_cnst)-1))]

# 3.2 mvt-DCC model -------------------
# We don't have access to the multivariate skewed-t distribution 

uni_spec <-  multispec(replicate(4, mod_ar_ngarch_skewt))

mod_dcc_ngarchskewt <- cgarchspec(uni_spec, dccOrder = c(1,1), distribution.model = list(copula = c("mvt")))
mod_fitting_dcc_ngarchskewt <- cgarchfit(mod_dcc_ngarchskewt, weekly_factors)

# 3.3 mvn-DCC model -----------------------

mod_dcc_normal_ngarchskewt <- cgarchspec(uni_spec, dccOrder = c(1,1), distribution.model = list(copula = c("mvnorm")))
mod_fitting_dcc_normal_ngarchskewt <- cgarchfit(mod_dcc_normal_ngarchskewt, weekly_factors)


# 3.4 mvt-CCC model ----------------------

mod_ccc_ngarchskewt <- cgarchspec(uni_spec, dccOrder = c(0,0), distribution.model = list(copula = c("mvt")))
mod_fitting_ccc_ngarchskewt <- cgarchfit(mod_ccc_ngarchskewt, weekly_factors)

# 3.5 Forecasts sandbox -----------------

scen <-  fscenario(weekly_factors, sim = 1000, model='cgarch', spec=mod_dcc_ngarchskewt)











