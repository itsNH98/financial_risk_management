# Financial Risk Management Project

**Note: Consider this as an ongoing project for future purposes. Not intended to be published in its actual state.**

## 1. Abstract

This project focuses on developing a robust tool for risk management and strategy evaluation in the financial domain. The main objectives are to generate backtesting returns data to apply strategies effectively, forecast risk measures for benchmark portfolios, and assess the risk of adding new strategies to existing portfolios. Additionally, we aim to improve the tool incrementally by incorporating new advanced methodologies such as multivariate volatility forecasting, copula models, extreme value theory and machine learning. We draw heavily from the work of Fortin, Simonato and Dionne (2023). 

The introduction provides an overview of the construction of stocks and portfolio data, exploration of the data, and determining the best model for portfolio data. The core of the study involves comparing the efficacy of multivariate and univariate models for portfolio value-at-risk (VaR) forecasting. Various research papers are reviewed to understand the advantages and disadvantages of each approach. The selection of the best ARCH specification and variance choice is also discussed based on empirical evidence from different studies.

The study further emphasizes the importance of robust estimation of risk parameters using simulations, such as VaR and Expected Shortfall (ES), and assesses the quality of risk measures through coverage and independence tests. Moreover, the research explores the potential improvement of the model by incorporating regime-switching models, extreme value theory, copulas, and combinations of various tools.

Overall, this study aims to contribute to the field of risk management and portfolio evaluation by providing a comprehensive and adaptable tool that incorporates the best methodologies for accurate risk assessment and strategy implementation in financial markets.

## 2. Detailed Plan

### 2.1 Objectives

1. UNIVARIATE VOLATILITY FORECASTING
    - Applicable to portfolios of equal weights over a fixed duration.
    - Could be used in the context of forecasting static portfolios, such as assessing the risk of a new asset.

2. MULTIVARIATE VOLATILITY FORECASTING
    - Best when in the context of dynamic portfolios of varying weight allocation.
    - Could be used in the context of adding a strategy to a pool of strategies, or testing a strategy in itself. 

3. IMPROVE THE FRAMEWORK INCREMENTALLY BY SUPPLEMENTING THE MAIN METHODOLOGIES AND ADDING NEW ONES 

### 2.2 Multivariate Worthiness: Is a multivariate risk framework worth it ?

We examine various approaches to forecasting risk measures, such as value-at-risk (VaR) and expected shortfall, in the context of financial risk management. This section considers both univariate and multivariate models and investigates their relative forecasting accuracies.

#### 2.2.1 Theoritical Findings

1. Santos (2009) Comparing univariate and multivariate models to forecast portfolio value-at-risk
    - Multivariate GARCH models seems to outperform competing univariate on OOS basis.

2. Fortin (2023) Forecasting expected shortfall: Should we use a multivariate model for stockmarket factors?
    - No significant differences between the risk forecasting accuracy of univariate and multivariate with dynamic correlations.

3. Brooks (2003) Volatility Forecasting for Risk Management
    - Relative accuracies of the various methods are highly sensitive to the measure used to evaluate them
    (not really about the differences in them)
    - Gain of using a multivariate GARCH model for forecasting volatility, which has not been previously investigated is minimal
    - Given the complexity, estimation difficulties and computer-intensive nature of MGARCH modelling, we conjecture that unless the conditional covariances are required, the estimation  of MGARCH is not worthwhile.

4. McAleer (2008) Single-Index and Portfolio Models for Forecasting Value-at-Risk Thresholds
    - Mixed evidence 
    - Index model lead to lower daily capital charges based on Basel

7. Diks (2020) Comparing density forecasts in a risk management context
    - Traditional way is to focus on forecasting the multivariate distribution and then assess downside risk.

8. Kole (2017) Tales From the Unit Interval: Backtesting, Forecasting and Modeling
    - The choice of a univariate or a multivariate model seem to not be particularly important, both types can generate good forecasts and neither is consistently better than the other

#### 2.2.2 Empirical Findings 

TBD 

#### 2.2.3 Conclusions 

In any case, we will have to consider both approaches to include static and dynamic portfolios within our framework. Review is interesting in any case, because it indicates that it will not be highly meaningful to do static portfolio variance forecasting by aggregating the volatility forecasts of the assets. I might even skip the empirical comparison between the two since the evidence is pretty much clear. 

### 2.3 Best Univariate model for static portfolios

#### 2.3.1 Theoritical Findings 

1. Alberg (2008) Estimating stock market volatility using asymmetric GARCH models
    - Asymmetric GARCH model with fat-tailed densities improves overall estimation for measuring conditional variance 
    - EGARCH with skewed student t distribution is the most successful 
    - Symmetric GARCH and ARCH models fail to capture the leverage effect
    - Another problem encountered when using GARCH is that they do not always fully embrace the thick tails property of financial time series

2. Chalissery (2022) Survey: Mapping the Trend
    - Most studies used EGARCH for modelling the asymmetric volatility effect, and most of them support it
    - Understanding of the causes is not improved with other specifications (only a way to mechanically improve prediction)

3. Dol (2021) Comparison of GARCH, EGARCH, etc in times of crisis
    - Results show that t-distribution performs best for all but one combination of model and dataset 
    - None of the Asymmetric models outperform the GARCH model (the GARCH model even significantly outperforms the GJR and TGARCH)

4. Mun Lim (2013) Comparing the GARCH in Malaysia 
    - Symmetric performs better during normal times and asymmetric better in crises

5. Orhan (2012) Comparison of GARCH models for VaR estimation 
    - ARCH and GARCH are the best specification, with student t

6. Srinivasan (2011) Modeling and Forecasting using GARCH models
    - Symmetric model does perform better in forecasting conditional variance of SP500

7. Blair (2010) Asymmetric and crash effects in stock volatility forthe S&P 100 index and its constituents
    - Past literature has confirmed the asymmetric relationship for individual stocks 
    - General similarity between the index and the constituent stocks
    
**Variance Choice**

1. Constant Variance 
    - Doesn't fit the distribution of returns
    - Doesn't take into account volatility clustering

2. ARCH (Engle 1982)
    - Assumes positive and negative shocks have the same effect
    - Restrictive parameters 
    - Over-Predicts Volatility

3. EWMA
    - Doesn't fit the distribution of returns

4. GARCH (Engle 1993)
    - Assumes positive and negative shocks have the same effect
    - Dol (2021) supports
    - Lim (2003) supports
    - Orhan (2012) supports
    - Srinivisan (2011) supports

5. RiskMetrics2006
    - Same as EWMA

6. HARCH (Muller 1992)
    - Too niche

7. EGARCH
    - Alberg (2008) supports
    - Chalissery (2022) supports

8. GJR-GARCH
    - Similar concept as the EGARCH (includes leverage component)

9. FIGARCH
    - No literature

10. MIDASHyperbolic
    - Too Niche 


#### 2.3.2 Empirical Findings

See 'univariate_model.ipynb'. We find that (i) models that allow for the leverage effect seem to improve variance prediction (ii) distribution assumptions that differ from the normal empirically create convergence problems and may result in very odd forecasts. 

#### 2.3.3 Conclusions

After theoritical and empirical findings considered, we will favor a model that allows for the leverage effect, notably the EGARCH. We also add an AR(3) mean process following Christoffersen (2012). Due to feasibility concerns, we limit our distributional assumptions to the normal and empirical (FHS).

## 2.4 Best Multivariate model for dynamic portfolios

### 2.4.1 Theoritical findings

TBD 

### 2.4.2 Empirical findings

TBD 

### 2.4.3 Conclusion 

TBD 


## 2.5 Forecast evaluation 

### 2.5.1 Theoritical findings

Measures: VAR, ES (Others?)
Tests: Coverage, Independence (Others?)

### 2.5.2 Empirical findings

TBD 

### 2.5.3 Conclusion 

TBD 

## 2.6 Additional Tools

### 2.6.1 Theoritical findings

#### 2.6.1.1 Machine Learning Models

1. Liu (2014)
    Takeaways:
2. Nabipour (2020)
    Takeaways:
3. Sook (2020)
    Takeaways:
4. Jiang (2021)
    Takeaways:
5. Kombure (2022)
    Takeaways:
5. Petroziello (2022)
    Takeaways:

#### 2.6.1.2 Regime Switching Models

Reviews:
1. Ang (2012)
    Takeaways:
2. Guidolin (2011)
    Takeaways:
3. Guidolin (2011)
    Takeaways:
4. Hamilton (2005)
    Takeways:

Applications:
1. Hardy (2014)
    Takeaways:
2. Hauptmann (2014)
    Takeaways:

#### 2.6.1.3 Extreme Value Theory 
        
Reviews:
1. Rocco (2012) 
    Takeaways: 
2. Bensalah (2000)
    Takeaways:

Multivariate:
1. Dupuis (2006)
    Takeaways:
2. Poon (2003)
    Takeaways: 

Risk Implications:
1. Gilli (2006)
    Takeaways:
2. Longin (2000)
    Takeaways:
        
#### 2.6.1.4 Copulas

Reviews:
1. Bouye (2000)
    Takeaways:
2. Patton (2007)
    Takeaways:
3. Genest (2009)
    Takeaways:
4. Patton (2012)
    Takeways:
5. Aas (2016)
    Takeways:

#### 2.6.1.5 Hybrid Models

TBD 

### 2.6.2 Empirical findings

TBD 

### 2.6.3 Conclusion 

TBD 

## 3. References 

### 3.1 Objectives

### 3.2 Multivariate Worthiness

Brooks, Chris, and Gita Persand. "Volatility forecasting for risk management." Journal of forecasting 22.1 (2003): 1-22.

McAleer, Michael, and Bernardo Da Veiga. "Single‐index and portfolio models for forecasting value‐at‐risk thresholds." Journal of Forecasting 27.3 (2008): 217-235.

Christoffersen, Peter. "Value–at–risk models." Handbook of financial time series. Berlin, Heidelberg: Springer Berlin Heidelberg, 2009. 753-766.

Santos, André AP, Francisco J. Nogales, and Esther Ruiz. "Comparing univariate and multivariate models to forecast portfolio value-at-risk." Journal of financial econometrics 11.2 (2013): 400-441.

Kole, Erik, et al. "Forecasting value-at-risk under temporal and portfolio aggregation." Journal of Financial Econometrics 15.4 (2017): 649-677.

De Almeida, Daniel, Luiz K. Hotta, and Esther Ruiz. "MGARCH models: Trade-off between feasibility and flexibility." International Journal of Forecasting 34.1 (2018): 45-63.

Diks, Cees, and Hao Fang. "Comparing density forecasts in a risk management context." International Journal of Forecasting 36.2 (2020): 531-551.

Fortin, Alain-Philippe, Jean-Guy Simonato, and Georges Dionne. "Forecasting expected shortfall: Should we use a multivariate model for stock market factors?." International Journal of Forecasting 39.1 (2023): 314-331.

### 3.3 Univariate Models

#### 3.3.1 Models 

Engle, Robert F. "Autoregressive conditional heteroscedasticity with estimates of the variance of United Kingdom inflation." Econometrica: Journal of the econometric society (1982): 987-1007.

Nelson, Daniel B. "Conditional heteroskedasticity in asset returns: A new approach." Econometrica: Journal of the econometric society (1991): 347-370.

Bollerslev, Tim. "Generalized autoregressive conditional heteroskedasticity." Journal of econometrics 31.3 (1986): 307-327.

Engle, Robert F., and Victor K. Ng. "Measuring and testing the impact of news on volatility." The journal of finance 48.5 (1993): 1749-1778.

Glosten, Lawrence R., Ravi Jagannathan, and David E. Runkle. "On the relation between the expected value and the volatility of the nominal excess return on stocks." The journal of finance 48.5 (1993): 1779-1801.

Müller, Ulrich A., et al. "Volatilities of different time resolutions—analyzing the dynamics of market components." Journal of Empirical Finance 4.2-3 (1997): 213-239.

Engle, Robert F., Eric Ghysels, and Bumjean Sohn. "Stock market volatility and macroeconomic fundamentals." Review of Economics and Statistics 95.3 (2013): 776-797.

Zakoian, Jean-Michel. "Threshold heteroskedastic models." Journal of Economic Dynamics and control 18.5 (1994): 931-955.

Oleg Komarov (2023). okomarov/importFrenchData (https://github.com/okomarov/importFrenchData), GitHub. Retrieved July 30, 2023.

#### 3.3.2 Comparison 

Day, Theodore E., and Craig M. Lewis. "Stock market volatility and the information content of stock index options." Journal of Econometrics 52.1-2 (1992): 267-287.

Braun, Phillip A., Daniel B. Nelson, and Alain M. Sunier. "Good news, bad news, volatility, and betas." The Journal of Finance 50.5 (1995): 1575-1603.

Hentschel, Ludger. "All in the family nesting symmetric and asymmetric garch models." Journal of financial economics 39.1 (1995): 71-104.

Koutmos, Gregory, and G. Geoffrey Booth. "Asymmetric volatility transmission in international stock markets." Journal of international Money and Finance 14.6 (1995): 747-762.

Booth, G. Geoffrey, Teppo Martikainen, and Yiuman Tse. "Price and volatility spillovers in Scandinavian stock markets." Journal of Banking & Finance 21.6 (1997): 811-823.

MCMillan, David, Alan Speight, and Owain Apgwilym. "Forecasting UK stock market volatility." Applied Financial Economics 10.4 (2000): 435-448.

Najand, Mohammad. "Forecasting stock index futures price volatility: Linear vs. nonlinear models." Financial Review 37.1 (2002): 93-104.

Lim, Ching Mun, and Siok Kun Sek. "Comparing the performances of GARCH-type models in capturing the stock market volatility in Malaysia." Procedia Economics and Finance 5 (2013): 478-487.

Ng, Hock Guan, and Michael McAleer. "Recursive modelling of symmetric and asymmetric volatility in the presence of extreme observations." International Journal of Forecasting 20.1 (2004): 115-129.

Sadorsky, Perry. "Modeling and forecasting petroleum futures volatility." Energy economics 28.4 (2006): 467-488.

McAleer, Michael, Felix Chan, and Dora Marinova. "An econometric analysis of asymmetric volatility: theory and application to patents." Journal of Econometrics 139.2 (2007): 259-284.

Alberg, Dima, Haim Shalit, and Rami Yosef. "Estimating stock market volatility using asymmetric GARCH models." Applied Financial Economics 18.15 (2008): 1201-1208.

Guidi, Francesco. "The economic effects of oil prices shocks on the UK manufacturing and services sector." (2009).

Blair, Bevan, Ser-Huang Poon, and Stephen J. Taylor. "Asymmetric and crash effects in stock volatility for the S&P 100 index and its constituents." Applied Financial Economics 12.5 (2002): 319-329.

Srinivasan, P. "Modeling and forecasting the stock market volatility of S&P 500 index using GARCH models." IUP Journal of Behavioral Finance 8.1 (2011): 51.

Orhan, Mehmet, and Bülent Köksal. "A comparison of GARCH models for VaR estimation." Expert Systems with Applications 39.3 (2012): 3582-3592.

Braione, Manuela, and Nicolas K. Scholtes. "Forecasting value-at-risk under different distributional assumptions." Econometrics 4.1 (2016): 3.

Dol, Misha. "Comparison of the GARCH, EGARCH, GJR-GARCH and TGARCH Model in Times of Crisis for the S&P500, NASDAQ and Dow-Jones." Erasmus School of Economics. https://thesis. eur. nl/pub/59759/Thesis-Misha-Dol-final-version. pdf (2021).

Chalissery, Neenu, et al. "Mapping the Trend, Application and Forecasting Performance of Asymmetric GARCH Models: A Review Based on Bibliometric Analysis." Journal of Risk and Financial Management 15.9 (2022): 406.

### 3.4 Multivariate Models 

TBD 

### 3.5 Evaluation 

Anatolyev, S. and Gerko, A. 2005, A trading approach to testing for predictability, Journal of Business and Economic Statistics, 23(4), 455–461.

Pesaran, M.H. and Timmermann, A. 1992, A simple nonparametric test of predictive performance, Journal of Business and Economic Statistics, 10(4), 461–465.

Christoffersen, P. and Pelletier, D. 2004, Backtesting value-at-risk: A duration-based approach,
Journal of Financial Econometrics, 2(1), 84–108.

Hansen, P. R., Lunde, A., and Nason, J. M., 2011. The model confidence set. Econometrica, 79(2),
453–497.

Christoffersen, P. (1998), Evaluating Interval Forecasts, International Economic Review, 39, 841–
862.

Christoffersen, P., Hahn,J. and Inoue, A. (2001), Testing and Comparing Value-at-Risk Measures,
Journal of Empirical Finance, 8, 325–342.

### 3.6 Other Tools 

#### 3.6.1 Machine learning

Liu, Yang. "Novel volatility forecasting using deep learning–long short term memory recurrent neural networks." Expert Systems with Applications 132 (2019): 99-109.

Kyoung-Sook, Moon, and Kim Hongjoong. "Performance of deep learning in prediction of stock market volatility." Economic Computation & Economic Cybernetics Studies & Research 53.2 (2019).

Petrozziello, Alessio, et al. "Deep learning for volatility forecasting in asset management." Soft Computing 26.17 (2022): 8553-8574.

Kumbure, Mahinda Mailagaha, et al. "Machine learning techniques and data for stock market forecasting: A literature review." Expert Systems with Applications 197 (2022): 116659.

Jiang, Weiwei. "Applications of deep learning in stock market prediction: recent progress." Expert Systems with Applications 184 (2021): 115537.

Nabipour, Mojtaba, et al. "Deep learning for stock market prediction." Entropy 22.8 (2020): 840.

#### 3.6.2 Regime Switching models

Hardy, Mary R. "A regime-switching model of long-term stock returns." North American Actuarial Journal 5.2 (2001): 41-53.

Hamilton, James D. "Regime switching models." Macroeconometrics and time series analysis. London: Palgrave Macmillan UK, 2010. 202-209.

Guidolin, Massimo. "Markov switching models in empirical finance." Missing data methods: Time-series methods and applications. Emerald Group Publishing Limited, 2011. 1-86.

Guidolin, Massimo. "Markov switching in portfolio choice and asset pricing models: A survey." Missing data methods: Time-series methods and applications. Vol. 27. Emerald Group Publishing Limited, 2011. 87-178.

Ang, Andrew, and Allan Timmermann. "Regime changes and financial markets." Annu. Rev. Financ. Econ. 4.1 (2012): 313-337.

Hauptmann, Johannes, et al. "Forecasting market turbulence using regime-switching models." Financial Markets and Portfolio Management 28 (2014): 139-164.

#### 3.6.3 Extreme Value Theory 

Bensalah, Younes. "Steps in applying extreme value theory to finance: a review." (2000).

Longin, Francois M. "From value at risk to stress testing: The extreme value approach." Journal of Banking & Finance 24.7 (2000): 1097-1130.

Poon, Ser-Huang, Michael Rockinger, and Jonathan Tawn. "Extreme value dependence in financial markets: Diagnostics, models, and financial implications." The Review of Financial Studies 17.2 (2004): 581-610.

Dupuis, Debbie J., and Bruce L. Jones. "Multivariate extreme value theory and its usefulness in understanding risk." North American Actuarial Journal 10.4 (2006): 1-27.

Gilli, Manfred, and Evis Këllezi. "An application of extreme value theory for measuring financial risk." Computational Economics 27 (2006): 207-228.

Rocco, Marco. "Extreme value theory in finance: A survey." Journal of Economic Surveys 28.1 (2014): 82-108.


#### 3.6.4 Copula Models 

Bouyé, Eric, et al. "Copulas for finance-a reading guide and some applications." Available at SSRN 1032533 (2000).

Patton, Andrew J. "Copula–based models for financial time series." Handbook of financial time series. Berlin, Heidelberg: Springer Berlin Heidelberg, 2009. 767-785.

Genest, Christian, Michel Gendron, and Michaël Bourdeau-Brien. "The advent of copulas in finance." Copulae and multivariate probability distributions in finance. Routledge, 2013. 1-10.

Patton, Andrew J. "A review of copula models for economic time series." Journal of Multivariate Analysis 110 (2012): 4-18.

Aas, Kjersti. "Pair-copula constructions for financial applications: A review." Econometrics 4.4 (2016): 43.

#### 3.6.5 Hybrid Models 

TBD 

