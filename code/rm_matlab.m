% Risk Management framework 
% Significantly based on the framework of Fortin & al (2023)
% Update: Will continue the project in R 

% ------------------------------
%|                             |
%|      1. Data Section        |
%|                             |
% ------------------------------

% 1.1 Returns Data  ------------------------

% Save the current working directory
mainDir = pwd;

% Change to the folder where the CSV file is located (replace 'relative/path/to/folder' with the actual relative path)
cd('../data/');

% Read the CSV file
returns_df = readtable('returns.csv'); 

% Change back to the original working directory
cd(mainDir);

% Convert 'Ticker' column to a string array
returns_df.Ticker = string(returns_df.Ticker);

% Logic to pivot the table
uniqueTickers = unique(returns_df.Ticker);
uniqueDates = unique(returns_df.DlyCalDt);

% Convert Ticker strings to numeric indices
tickerIndices = grp2idx(returns_df.Ticker);

% Initialize the pivoted table with NaNs
pivotedReturns = array2table(NaN(length(uniqueDates), length(uniqueTickers)), 'RowNames', string(uniqueDates));

% Logic to pivot the table according to tickers and return values
for i = 1:length(uniqueTickers)
    ticker = uniqueTickers(i);
    idx = tickerIndices == i;
    
    % Get the 'DlyRet' values for the current ticker
    retValues = returns_df.DlyRet(idx);
    
    % Get the dates for the current ticker
    tickerDates = returns_df.DlyCalDt(idx);
    
    % Find the indices of the dates in uniqueDates that match the current ticker dates
    [~, loc] = ismember(tickerDates, uniqueDates);
    
    % Assign the 'DlyRet' values to the corresponding column of the pivotedTable
    pivotedReturns(loc, i) = num2cell(retValues);
end

% Set the variable names as the unique tickers
pivotedReturns.Properties.VariableNames = uniqueTickers;

% Log Returns 
pivotedReturnsMatrix = table2array(pivotedReturns);
logReturnsMatrix = log(1+pivotedReturnsMatrix);

% Resample
logReturnsTable = array2table(logReturnsMatrix, 'VariableNames', pivotedReturns.Properties.VariableNames, 'RowNames', pivotedReturns.Properties.RowNames);

weeklyLogReturnsTable = resample(logReturnsTable);

% 1.2 FF Factors Data ----------------------------------

% Add path for matlab functions
folderPath = './matlab_functions/';
addpath(folderPath);

% Merge Momentum and FF Tables
FF = importFrenchData('F-F_Research_Data_Factors_daily_TXT.zip');
MOM = importFrenchData('F-F_Momentum_Factor_daily_TXT.zip');
mergedTable = innerjoin(FF, MOM, 'Keys', 'Date');
% mergedTable.Date = datetime(mergedTable.Date, 'Format', 'yyyyMMdd');

% Slice by Date
logicalIndex = (mergedTable.Date >= 19630705) & (mergedTable.Date <= 20191231);
factors = mergedTable(logicalIndex, :);

% Divide by 100 to get % 
colsToDivide = {'MktMinusRF', 'SMB', 'HML', 'Mom'};
for i = 1:length(colsToDivide)
    factors.(colsToDivide{i}) = factors.(colsToDivide{i}) / 100;
end

factors = removevars(factors, 'RF');

% Log Returns
factors.Date = datetime(string(factors.Date), 'InputFormat', 'yyyyMMdd');
factors.Date = datetime(factors.Date, 'Format', 'yyyy-MM-dd'); % Convert to the desired output format
rowNames = factors.Date; % Extract the column values as row names
factors.Date = []; % Remove the column from the table
factors.Properties.RowNames = cellstr(datetime(rowNames, 'InputFormat','yyyy-MM-dd'));

factorsMatrix = table2array(factors);
logFactors = log(1 + factorsMatrix);
logFFTable = array2table(logFactors, 'VariableNames', factors.Properties.VariableNames, 'RowNames', factors.Properties.RowNames);

% Resampling
weeklyLogFactors = resample(logFFTable);

% 1.3 Descriptive Statistics -------------------------------

weeklyLogReturnsArray = table2array(weeklyLogReturnsTable(:, ~strcmp(weeklyLogReturnsTable.Properties.VariableNames, 'Time')));
weeklyLogFactorsArray = table2array(weeklyLogFactors(:, ~strcmp(weeklyLogFactors.Properties.VariableNames, 'Time')));

meanReturns = nanmean(weeklyLogReturnsArray);
meanFactors = nanmean(weeklyLogFactorsArray);

stdReturns = nanstd(weeklyLogReturnsArray);
stdFactors = nanstd(weeklyLogFactorsArray);


% 1.4 EW Stock Portfolios ---------------------------------

% Log Returns are not additive so has to be with raw returns data

% Preallocate an array to store the portfolio returns
numDates = length(pivotedReturns.Properties.RowNames);
portfolioReturns = NaN(numDates, 1);

% Loop through each date
for i = 1:numDates
    % Get the returns for the current date
    returnsAtDate = pivotedReturnsMatrix(i, :);
    
    % Find stocks with non-NaN values for the current date
    validStocks = ~isnan(returnsAtDate);
    
    % Filter returnsAtDate to keep only valid stocks
    returnsAtDateFiltered = returnsAtDate(validStocks);
    
    % Calculate the number of valid stocks for the current date
    numStocks = sum(validStocks);
    
    % Check if there are valid stocks for the current date
    if numStocks > 0
        % Calculate the equal weights for valid stocks
        weights = ones(1, numStocks) / numStocks;
        
        % Calculate the equal-weighted portfolio return for the current date
        portfolioReturns(i) = sum(weights .* returnsAtDateFiltered);
    end
end

% Log Returns
logPortfolioReturns = log(1 + portfolioReturns);

% Create the logPortfolioReturnsTable with dates as row names
logPortfolioReturnsTable = array2table(logPortfolioReturns, 'VariableNames', {'EW'}, 'RowNames', pivotedReturns.Properties.RowNames);

weeklyLogPR = resample(logPortfolioReturnsTable);

weeklyLogPRVector = table2array(weeklyLogPR(:, 2));


% ------------------------------
%|                             |
%| 2. Core Univariate Section  |
%|                             |
% ------------------------------

% Based on model evaluation in Python, we opt for the AR(3)-EGARCH
% specification, although Fortin uses AR(3)-NGARCH

% 2.1 Model estimation (AR3-EGARCH) ----------------------

% Variance and mean model in two-steps
varMdl = egarch('GARCHLags',1,'ARCHLags',1,'LeverageLags',1,'Offset', 0);
Mdl = arima('ARLags',3,'Variance',varMdl);

% Using weekly log returns
estMdl = estimate(Mdl, weeklyLogPRVector);

% 2.2 Forecasting Model Example ---------------------------

% numPeriods = 1;
% vF = forecast(estMdl,numPeriods, weeklyLogPRVector);
% v = infer(estMdl,weeklyLogPRVector);

% figure;
% plot(weeklyLogPR.Time, v,'k:','LineWidth',2);
% hold on;
% plot(weeklyLogPR.Time(end):weeklyLogPR.Time(end) + 10,[v(end);vF],'r','LineWidth',2);
% title('Forecasted Conditional Variances of EW Returns');
% ylabel('Conditional variances');
% xlabel('Year');
% legend({'Estimation sample cond. var.','Forecasted cond. var.'},...
%     'Location','Best');


% 2.3 Rolling window conditional variance forecasting ------------

% Set the rolling window size

windowSize = (52*20); 

% Initialize arrays to store the forecasted conditional volatility

numWindows = length(weeklyLogPRVector) - windowSize + 1;
forecastedVolatility = NaN(numWindows, 1);

% Perform rolling window forecasting
for i = 1:numWindows
    % Extract the current window
    currentWindow = weeklyLogPRVector(i:i+windowSize-1);
    
    % Estimate the EGARCH model on the current window
    varMdl = egarch('GARCHLags', 1, 'ARCHLags', 1, 'LeverageLags', 1, 'Offset', 0);
    Mdl = arima('ARLags', 3, 'Variance', varMdl);
    estMdl = estimate(Mdl, currentWindow);
    
    % Forecast the conditional volatility at horizon 1
    forecastedVolatility(i) = sqrt(forecast(estMdl, 1, 'Y0', currentWindow(end-2:end)));
end

% Plot the rolling window forecasted volatility
figure;
plot(forecastedVolatility);
xlabel('Window End Index');
ylabel('Forecasted Volatility at Horizon 1');
title('Rolling Window Forecast of Conditional Volatility');


% ------------------------------
%|                             |
%| 3.Core Multivariate Section |
%|                             |
% ------------------------------


% 3.1 MFE Toolbox Sandbox -----------------------

cd('~/Documents/MATLAB/mfe-toolbox-main/');
addToPath()

cd(mainDir)

% arimax filtering  
P = 3;
[armaParams, armaLL, armaResid] = armaxfilter(weeklyLogPRVector,1,1:P); 

% garch filtering 
garchParams = tarch(armaResid, 1, 0, 1);

% 3.2 MFE Multivariate Model on Factors ---------

% VAR Prewhitening 
[parametersVAR,stderrVAR,tstatVAR,pvalVAR,constVAR,conststdVAR,r2VAR,errorsVAR,s2VAR,paramvecVAR,vcvVAR] = vectorar(weeklyLogFactorsArray,1,1:3);

% DCC-Model fitting 
[parameters, ll ,Ht, VCV, scores, diagnostics]= dcc(errorsVAR,[],1,0,1);

% There doesn't seem to be a function for forecasting anything with DCC

% I have been told by Alain-Philippe that they coded all the functions
% themselves for multivariate models and copulas. Fortunately, most of 
% these functions are available in R. I will continue this project
% within the R framework.





