clc; clear; close all force;

% load data
libdata = data();

% lecture dataset
[lecRets, frequency] = libdata.readLectureDataset();
rets = lecRets;

% S&P 500 dataset
% [sp500IdxRets, sp500StockRets, frequency] = libdata.readSP500Dataset();
% simpleRets = sp500StockRets;
% simpleRets = sp500IdxRets;

cumRets = libdata.cumulativeReturns(rets);

% data summary statistics
libdata.summaryStats(rets, frequency)



% backtest
libbacktest = backtest();
librets = expectedReturnsEstimation();
libcov = covarianceEstimation();
libportopt = portfolioOptimizer();

estimationWindow = 12/12 * frequency;
estimationInterval = 3/12 * frequency;
startIndex = estimationWindow + 1;

movingWndDataFunc = @(rets, idx) libdata.extractWindow(rets, idx, estimationWindow);
movingWndFutureDataFunc = @(rets, idx) libdata.extractWindow(rets, idx + estimationWindow, estimationWindow);


% 1/N
cfg1 = BacktestConfig('1/N');
cfg1.ExpectedRetsFunc = @librets.expMovingAverage;
cfg1.ExpectedRetsDataFunc = movingWndDataFunc;
cfg1.CovFunc = @libcov.sampleCovShrinkageOAS;
cfg1.CovDataFunc = movingWndDataFunc;
cfg1.PortOptimizerFunc = @libportopt.EqualWeights;
cfg1.EstimationInterval = estimationInterval;
cfg1.RebalancingInterval = estimationInterval;
cfg1.Returns = rets;
cfg1.Securities = rets.Properties.VariableNames;
cfg1.StartIndex = startIndex;

% Minimum Variance
cfg2 = BacktestConfig('Minimum Variance');
cfg2.ExpectedRetsFunc = @librets.expMovingAverage;
cfg2.ExpectedRetsDataFunc = movingWndDataFunc;
cfg2.CovFunc = @libcov.sampleCovShrinkageOAS;
cfg2.CovDataFunc = movingWndDataFunc;
cfg2.PortOptimizerFunc = @libportopt.MinVariance;
cfg2.EstimationInterval = estimationInterval;
cfg2.RebalancingInterval = estimationInterval;
cfg2.Returns = rets;
cfg2.Securities = rets.Properties.VariableNames;
cfg2.StartIndex = startIndex;

% Maximum Sharpe Ratio
cfg3 = BacktestConfig('Maximum Sharpe Ratio');
cfg3.ExpectedRetsFunc = @librets.expMovingAverage;
cfg3.ExpectedRetsDataFunc = movingWndDataFunc;
cfg3.CovFunc = @libcov.sampleCovShrinkageOAS;
cfg3.CovDataFunc = movingWndDataFunc;
cfg3.PortOptimizerFunc = @libportopt.MaxSharpeRatio;
cfg3.EstimationInterval = estimationInterval;
cfg3.RebalancingInterval = estimationInterval;
cfg3.Returns = rets;
cfg3.Securities = rets.Properties.VariableNames;
cfg3.StartIndex = startIndex;

% Maximum SR (perfect information)
cfg4 = BacktestConfig('Maximum Sharpe Ratio (perfect information)');
cfg4.ExpectedRetsFunc = @librets.arithmeticMean;
cfg4.ExpectedRetsDataFunc = movingWndFutureDataFunc;
cfg4.CovFunc = @libcov.sampleCovShrinkageOAS;
cfg4.CovDataFunc = movingWndFutureDataFunc;
cfg4.PortOptimizerFunc = @libportopt.MaxSharpeRatio;
cfg4.EstimationInterval = estimationInterval;
cfg4.RebalancingInterval = estimationInterval;
cfg4.Returns = rets;
cfg4.Securities = rets.Properties.VariableNames;
cfg4.StartIndex = startIndex;

% list of backtest configs
bCfg = {cfg1, cfg2, cfg3, cfg4};

% list of backtest results
bRes = {};

% all backtest portfolio returns in timetable
bRets = timetable(rets.Date);
bRets.Properties.DimensionNames = {'Date', 'Returns'};

for i=1:length(bCfg)
    bRes{i} = libbacktest.execute(bCfg{i});
    bRets = addvars(bRets, bRes{i}.PortfolioReturns{:, 1}, 'NewVariableNames', bCfg{i}.Name);
end

% cumulative portfolio returns
bCumRets = libdata.cumulativeReturns(bRets);

% Sharpe ratios
SR = libdata.sharpeRatio(bRets, frequency);
disp("\nPortfolio Sharpe Ratios");
disp([bRets.Properties.VariableNames' num2cell(SR)]);





libvis = visualize();



figure(1)
for i=1:length(bRes)
    wgts = bRes{i}.PortfolioWeights;
    
    subplot(length(bRes), 1, i);
    area(wgts{:, :})
    legend(bRes{i}.Config.Securities, 'Location', 'NorthEastOutside')
    title(strcat("Allocation over time: ", bRes{i}.Config.Name))
    ylabel('Allocation')
    axis([bRes{i}.Config.StartIndex size(wgts, 1) 0 1])
    % set(gca, 'XTick', ticks)
    % set(gca, 'XTickLabel', datestr(xTickNames,12))
end



        
        

% plot strategy returns
figure(2)
subplot(2, 1, 1); libvis.plotReturns('Strategy cumulative returns', bCumRets)



% plot returns of asset classes
% figure(2)
subplot(2, 1, 2); libvis.plotReturns('Asset class returns', cumRets)
% subplot(3, 2, 1); libvis.plotReturns('Cash', cumRets(:, 1))
% subplot(3, 2, 2); libvis.plotReturns('Bonds', cumRets(:, 2:6))
% subplot(3, 2, 3); libvis.plotReturns('Equities', cumRets(:, 7:10))
% subplot(3, 2, 4); libvis.plotReturns('Alternative', cumRets(:, 11:12))
% subplot(3, 2, 5); libvis.plotReturns('Commodities', cumRets(:, 13))







