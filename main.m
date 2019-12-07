% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

clc; clear; close all force;

addpath('classes');


% load data
libdata = libdata();

% % NASDAQ-100
% [datasetName, stockRets, frequency] = libdata.readNASDAQ100Dataset();
% rets = stockRets(100:end, 280:end);

% % Dow Jones Industrial Average 30
% [datasetName, stockRets, frequency] = libdata.readDJIA30Dataset();
% rets = stockRets;

% lecture dataset
[datasetName, lecRets, frequency] = libdata.readLectureDataset();
rets = lecRets;

% % lecture dataset w/o `Cash CHF`
% [datasetName, lecRets, frequency] = libdata.readLectureNoCashDataset();
% rets = lecRets;

% Strategic Asset Allocation
SAA = libdata.readSAA();


% backtest
librets = libreturns();
libcov = libcovariance();
libopt = liboptimizer();
libconst = libconstraints();

estimationWindow = 4 * frequency;
optimizationInterval = 0.5 * frequency;
rebalancingInterval = 0.5 * frequency;
startIndex = estimationWindow + 1;

movingWndDataFunc = @(rets, idx) libdata.extractWindow(rets, idx, estimationWindow);
movingWndFutureDataFunc = @(rets, idx) libdata.extractWindow(rets, idx + estimationWindow, estimationWindow);

maxWeight = 0.20;

% unique identifier of backtest, used for filename of plots/results in folder `output`
specialSuffix = '_';
backtestIdentifier = sprintf('dataset=%s,wnd=%.1fyrs,opt.int.=%.1fyrs,max.wgt=%.2f,freq=%.0f%s', datasetName, estimationWindow / frequency, optimizationInterval / frequency, maxWeight, frequency, specialSuffix);



EQW = BacktestConfig('EQW', '1/N');
EQW.ExpectedRetsDataFunc = movingWndDataFunc;
EQW.CovFunc = @libcov.sampleCov;
EQW.CovDataFunc = movingWndDataFunc;
EQW.PortOptimizerFunc = @libopt.EqualWeights;
EQW.OptimizationInterval = optimizationInterval;
EQW.RebalancingInterval = rebalancingInterval;
EQW.Returns = rets;
EQW.Securities = rets.Properties.VariableNames;
EQW.StartIndex = startIndex;

MVAR = BacktestConfig('MVAR', 'Minimum Variance');
MVAR.ExpectedRetsFunc = @librets.exponentialSmoothing;
MVAR.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR.CovFunc = @libcov.sampleCov;
MVAR.CovDataFunc = movingWndDataFunc;
MVAR.PortOptimizerFunc = @libopt.MinVariance;
MVAR.ConstraintsFunc = @libconst.defaultConstraints;
MVAR.OptimizationInterval = optimizationInterval;
MVAR.RebalancingInterval = rebalancingInterval;
MVAR.Returns = rets;
MVAR.Securities = rets.Properties.VariableNames;
MVAR.StartIndex = startIndex;

MVAR_shrink = BacktestConfig('MVAR_shr', 'Minimum Variance (shrinkage)');
MVAR_shrink.ExpectedRetsFunc = @librets.exponentialSmoothing;
MVAR_shrink.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR_shrink.CovFunc = @libcov.sampleCovShrinkageOAS;
MVAR_shrink.CovDataFunc = movingWndDataFunc;
MVAR_shrink.PortOptimizerFunc = @libopt.MinVariance;
MVAR_shrink.ConstraintsFunc = @libconst.defaultConstraints;
MVAR_shrink.OptimizationInterval = optimizationInterval;
MVAR_shrink.RebalancingInterval = rebalancingInterval;
MVAR_shrink.Returns = rets;
MVAR_shrink.Securities = rets.Properties.VariableNames;
MVAR_shrink.StartIndex = startIndex;

MVAR_shrink_fixed_const = BacktestConfig('MVAR_shr_fix', sprintf('Minimum Variance (shrinkage, %.0f%% max weight)', maxWeight*100));
MVAR_shrink_fixed_const.ExpectedRetsFunc = @librets.exponentialSmoothing;
MVAR_shrink_fixed_const.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR_shrink_fixed_const.CovFunc = @libcov.sampleCovShrinkageOAS;
MVAR_shrink_fixed_const.CovDataFunc = movingWndDataFunc;
MVAR_shrink_fixed_const.PortOptimizerFunc = @libopt.MinVariance;
MVAR_shrink_fixed_const.ConstraintsFunc = @(optParams) libconst.equalMaxWeight(optParams, maxWeight);
MVAR_shrink_fixed_const.OptimizationInterval = optimizationInterval;
MVAR_shrink_fixed_const.RebalancingInterval = rebalancingInterval;
MVAR_shrink_fixed_const.Returns = rets;
MVAR_shrink_fixed_const.Securities = rets.Properties.VariableNames;
MVAR_shrink_fixed_const.StartIndex = startIndex;

MVAR_shrink_SAA = BacktestConfig('MVAR_shr_SAA', 'Minimum Variance (shrinkage, SAA)');
MVAR_shrink_SAA.ExpectedRetsFunc = @librets.exponentialSmoothing;
MVAR_shrink_SAA.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR_shrink_SAA.CovFunc = @libcov.sampleCovShrinkageOAS;
MVAR_shrink_SAA.CovDataFunc = movingWndDataFunc;
MVAR_shrink_SAA.PortOptimizerFunc = @libopt.MinVariance;
MVAR_shrink_SAA.ConstraintsFunc = @(optParams) libconst.imposeSAAonAssetClasses(optParams, SAA, maxWeight);
MVAR_shrink_SAA.OptimizationInterval = optimizationInterval;
MVAR_shrink_SAA.RebalancingInterval = rebalancingInterval;
MVAR_shrink_SAA.Returns = rets;
MVAR_shrink_SAA.Securities = rets.Properties.VariableNames;
MVAR_shrink_SAA.StartIndex = startIndex;

MSR_SMA = BacktestConfig('MSR', 'Maximum Sharpe Ratio');
MSR_SMA.ExpectedRetsFunc = @librets.simpleMean;
MSR_SMA.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_SMA.CovFunc = @libcov.sampleCov;
MSR_SMA.CovDataFunc = movingWndDataFunc;
MSR_SMA.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSR_SMA.ConstraintsFunc = @libconst.defaultConstraints;
MSR_SMA.OptimizationInterval = optimizationInterval;
MSR_SMA.RebalancingInterval = rebalancingInterval;
MSR_SMA.Returns = rets;
MSR_SMA.Securities = rets.Properties.VariableNames;
MSR_SMA.StartIndex = startIndex;

% MSR_EWMA = BacktestConfig('MSR_EWMA', 'Maximum Sharpe Ratio (EWMA)');
% MSR_EWMA.ExpectedRetsFunc = @librets.exponentialSmoothing;
% MSR_EWMA.ExpectedRetsDataFunc = movingWndDataFunc;
% MSR_EWMA.CovFunc = @libcov.sampleCov;
% MSR_EWMA.CovDataFunc = movingWndDataFunc;
% MSR_EWMA.PortOptimizerFunc = @libopt.MaxSharpeRatio;
% MSR_EWMA.ConstraintsFunc = @libconst.defaultConstraints;
% MSR_EWMA.OptimizationInterval = optimizationInterval;
% MSR_EWMA.RebalancingInterval = rebalancingInterval;
% MSR_EWMA.Returns = rets;
% MSR_EWMA.Securities = rets.Properties.VariableNames;
% MSR_EWMA.StartIndex = startIndex;

MSR_SMA_shrink = BacktestConfig('MSR_shr', 'Maximum Sharpe Ratio (shrinkage)');
MSR_SMA_shrink.ExpectedRetsFunc = @librets.simpleMean;
MSR_SMA_shrink.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_SMA_shrink.CovFunc = @libcov.sampleCovShrinkageOAS;
MSR_SMA_shrink.CovDataFunc = movingWndDataFunc;
MSR_SMA_shrink.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSR_SMA_shrink.ConstraintsFunc = @libconst.defaultConstraints;
MSR_SMA_shrink.OptimizationInterval = optimizationInterval;
MSR_SMA_shrink.RebalancingInterval = rebalancingInterval;
MSR_SMA_shrink.Returns = rets;
MSR_SMA_shrink.Securities = rets.Properties.VariableNames;
MSR_SMA_shrink.StartIndex = startIndex;

% MSR_EWMA_shrink = BacktestConfig('MSR_EWMA_shrink', 'Maximum Sharpe Ratio (EWMA, shrinkage)');
% MSR_EWMA_shrink.ExpectedRetsFunc = @librets.exponentialSmoothing;
% MSR_EWMA_shrink.ExpectedRetsDataFunc = movingWndDataFunc;
% MSR_EWMA_shrink.CovFunc = @libcov.sampleCovShrinkageOAS;
% MSR_EWMA_shrink.CovDataFunc = movingWndDataFunc;
% MSR_EWMA_shrink.PortOptimizerFunc = @libopt.MaxSharpeRatio;
% MSR_EWMA_shrink.ConstraintsFunc = @libconst.defaultConstraints;
% MSR_EWMA_shrink.OptimizationInterval = optimizationInterval;
% MSR_EWMA_shrink.RebalancingInterval = rebalancingInterval;
% MSR_EWMA_shrink.Returns = rets;
% MSR_EWMA_shrink.Securities = rets.Properties.VariableNames;
% MSR_EWMA_shrink.StartIndex = startIndex;

MSR_shrink_fixed_const = BacktestConfig('MSR_shr_fix', sprintf('Maximum Sharpe Ratio (shrinkage, %.0f%% max weight)', maxWeight*100));
MSR_shrink_fixed_const.ExpectedRetsFunc = @librets.exponentialSmoothing;
MSR_shrink_fixed_const.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_shrink_fixed_const.CovFunc = @libcov.sampleCovShrinkageOAS;
MSR_shrink_fixed_const.CovDataFunc = movingWndDataFunc;
MSR_shrink_fixed_const.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSR_shrink_fixed_const.ConstraintsFunc = @(optParams) libconst.equalMaxWeight(optParams, maxWeight);
MSR_shrink_fixed_const.OptimizationInterval = optimizationInterval;
MSR_shrink_fixed_const.RebalancingInterval = rebalancingInterval;
MSR_shrink_fixed_const.Returns = rets;
MSR_shrink_fixed_const.Securities = rets.Properties.VariableNames;
MSR_shrink_fixed_const.StartIndex = startIndex;

MSR_shrink_SAA = BacktestConfig('MSR_shr_SAA', 'Maximum Sharpe Ratio (shrinkage, SAA)');
MSR_shrink_SAA.ExpectedRetsFunc = @librets.exponentialSmoothing;
MSR_shrink_SAA.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_shrink_SAA.CovFunc = @libcov.sampleCovShrinkageOAS;
MSR_shrink_SAA.CovDataFunc = movingWndDataFunc;
MSR_shrink_SAA.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSR_shrink_SAA.ConstraintsFunc = @(optParams) libconst.imposeSAAonAssetClasses(optParams, SAA, maxWeight);
MSR_shrink_SAA.OptimizationInterval = optimizationInterval;
MSR_shrink_SAA.RebalancingInterval = rebalancingInterval;
MSR_shrink_SAA.Returns = rets;
MSR_shrink_SAA.Securities = rets.Properties.VariableNames;
MSR_shrink_SAA.StartIndex = startIndex;

MSRP_SMA = BacktestConfig('MSRP', 'Maximum Sharpe Ratio (perfect information)');
MSRP_SMA.ExpectedRetsFunc = @librets.simpleMean;
MSRP_SMA.ExpectedRetsDataFunc = movingWndFutureDataFunc;
MSRP_SMA.CovFunc = @libcov.sampleCov;
MSRP_SMA.CovDataFunc = movingWndFutureDataFunc;
MSRP_SMA.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSRP_SMA.ConstraintsFunc = @libconst.defaultConstraints;
MSRP_SMA.OptimizationInterval = optimizationInterval;
MSRP_SMA.RebalancingInterval = rebalancingInterval;
MSRP_SMA.Returns = rets;
MSRP_SMA.Securities = rets.Properties.VariableNames;
MSRP_SMA.StartIndex = startIndex;

MSRP_SMA_shrink = BacktestConfig('MSRP_shr', 'Maximum Sharpe Ratio (perfect information, shrinkage)');
MSRP_SMA_shrink.ExpectedRetsFunc = @librets.simpleMean;
MSRP_SMA_shrink.ExpectedRetsDataFunc = movingWndFutureDataFunc;
MSRP_SMA_shrink.CovFunc = @libcov.sampleCovShrinkageOAS;
MSRP_SMA_shrink.CovDataFunc = movingWndFutureDataFunc;
MSRP_SMA_shrink.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSRP_SMA_shrink.ConstraintsFunc = @libconst.defaultConstraints;
MSRP_SMA_shrink.OptimizationInterval = optimizationInterval;
MSRP_SMA_shrink.RebalancingInterval = rebalancingInterval;
MSRP_SMA_shrink.Returns = rets;
MSRP_SMA_shrink.Securities = rets.Properties.VariableNames;
MSRP_SMA_shrink.StartIndex = startIndex;

ERC = BacktestConfig('ERC', 'Equal Risk Contribution');
ERC.ExpectedRetsFunc = @librets.exponentialSmoothing;
ERC.ExpectedRetsDataFunc = movingWndDataFunc;
ERC.CovFunc = @libcov.sampleCov;
ERC.CovDataFunc = movingWndDataFunc;
ERC.PortOptimizerFunc = @libopt.EqualRiskContribution;
ERC.ConstraintsFunc = @libconst.defaultConstraints;
ERC.OptimizationInterval = optimizationInterval;
ERC.RebalancingInterval = rebalancingInterval;
ERC.Returns = rets;
ERC.Securities = rets.Properties.VariableNames;
ERC.StartIndex = startIndex;

ERC_shrink = BacktestConfig('ERC_shr', 'Equal Risk Contribution (shrinkage)');
ERC_shrink.ExpectedRetsFunc = @librets.exponentialSmoothing;
ERC_shrink.ExpectedRetsDataFunc = movingWndDataFunc;
ERC_shrink.CovFunc = @libcov.sampleCovShrinkageOAS;
ERC_shrink.CovDataFunc = movingWndDataFunc;
ERC_shrink.PortOptimizerFunc = @libopt.EqualRiskContribution;
ERC_shrink.ConstraintsFunc = @libconst.defaultConstraints;
ERC_shrink.OptimizationInterval = optimizationInterval;
ERC_shrink.RebalancingInterval = rebalancingInterval;
ERC_shrink.Returns = rets;
ERC_shrink.Securities = rets.Properties.VariableNames;
ERC_shrink.StartIndex = startIndex;

ERC_shrink_fixed_const = BacktestConfig('ERC_shr_fix', sprintf('Equal Risk Contribution (shrinkage, %.0f%% max weight)', maxWeight*100));
ERC_shrink_fixed_const.ExpectedRetsFunc = @librets.exponentialSmoothing;
ERC_shrink_fixed_const.ExpectedRetsDataFunc = movingWndDataFunc;
ERC_shrink_fixed_const.CovFunc = @libcov.sampleCovShrinkageOAS;
ERC_shrink_fixed_const.CovDataFunc = movingWndDataFunc;
ERC_shrink_fixed_const.PortOptimizerFunc = @libopt.EqualRiskContribution;
ERC_shrink_fixed_const.ConstraintsFunc = @(optParams) libconst.equalMaxWeight(optParams, maxWeight);
ERC_shrink_fixed_const.OptimizationInterval = optimizationInterval;
ERC_shrink_fixed_const.RebalancingInterval = rebalancingInterval;
ERC_shrink_fixed_const.Returns = rets;
ERC_shrink_fixed_const.Securities = rets.Properties.VariableNames;
ERC_shrink_fixed_const.StartIndex = startIndex;

ERC_shrink_SAA = BacktestConfig('ERC_shr_SAA', 'Equal Risk Contribution (shrinkage, SAA)');
ERC_shrink_SAA.ExpectedRetsFunc = @librets.exponentialSmoothing;
ERC_shrink_SAA.ExpectedRetsDataFunc = movingWndDataFunc;
ERC_shrink_SAA.CovFunc = @libcov.sampleCovShrinkageOAS;
ERC_shrink_SAA.CovDataFunc = movingWndDataFunc;
ERC_shrink_SAA.PortOptimizerFunc = @libopt.EqualRiskContribution;
ERC_shrink_SAA.ConstraintsFunc = @(optParams) libconst.imposeSAAonAssetClasses(optParams, SAA, maxWeight);
ERC_shrink_SAA.OptimizationInterval = optimizationInterval;
ERC_shrink_SAA.RebalancingInterval = rebalancingInterval;
ERC_shrink_SAA.Returns = rets;
ERC_shrink_SAA.Securities = rets.Properties.VariableNames;
ERC_shrink_SAA.StartIndex = startIndex;





% ------------------------------------
% list of various backtest configs
% ------------------------------------

% % (1) naive approach: sample covariance, simple mean
% bCfg = { MSR_SMA, MSRP_SMA, MVAR, ERC };
% prefix = '1_';

% % (2) sample covariance vs. shrinkage estimator
% bCfg = { MSR_SMA, MSR_SMA_shrink, MVAR, MVAR_shrink };
% prefix = '2_';

% % (3) sample covariance vs. shrinkage estimator under perfect information
% bCfg = { MSRP_SMA, MSRP_SMA_shrink };
% prefix = '3_';

% (4) where we are now - different methods
bCfg = { EQW, MVAR_shrink, MSR_SMA_shrink, ERC_shrink };
prefix = '4_';

% % (5) unconstrained vs. fixed max. weight constraint
% bCfg = { EQW, MVAR_shrink, MVAR_shrink_fixed_const, MSR_shrink_fixed_const, ERC_shrink, ERC_shrink_fixed_const };
% prefix = '5_';

% % (6) impose SAA
% bCfg = { EQW, MVAR_shrink_SAA, MSR_shrink_SAA, ERC_shrink_SAA };
% prefix = '6_';



% run backtests in parallel
bRes = {};
parallel = true;

if parallel
    parfor i=1:length(bCfg)
        bRes{i} = libbacktest().execute(bCfg{i});
    end
else
    for i=1:length(bCfg)
        bRes{i} = libbacktest().execute(bCfg{i});
    end
end

% add backtest names to backtest identifier string
for i=1:length(bCfg)
    backtestIdentifier = strcat(backtestIdentifier, '[', bCfg{i}.Name, ']');
end
backtestIdentifier = strcat(backtestIdentifier, '_');
backtestIdentifier = strcat(prefix, backtestIdentifier);


% store backtest portfolio returns in one timetable
bRets = timetable(rets.Date);
bRets.Properties.DimensionNames = {'Date', 'Returns'};

for i=1:length(bCfg)
    bRets = addvars(bRets, bRes{i}.PortfolioRets{:, 1}, 'NewVariableNames', bCfg{i}.Label);
end




% ====================================================================================================
% Plot charts, print summary statistics.
% ----------------------------------------------------------------------------------------------------
% Saves text output and PDF of plots into subfolder `output`.
% ====================================================================================================

log = liblog();

% data summary statistics
nAssets = size(rets, 2);
cumRets = libdata.cumulativeReturns(rets);

disp(libdata.summaryStats(rets, frequency));

% log to file
log.writeTo(evalc("disp(libdata.summaryStats(rets, frequency))"), sprintf("output/dataset=%s-data_summary.txt", datasetName));





% Sharpe ratios
SR = libdata.sharpeRatio(bRets, frequency);
disp(' ');
disp("    Portfolio Sharpe Ratios");
disp("    -------------------------------------");
disp([bRets.Properties.VariableNames' num2cell(SR)]);

% log to file
log.writeTo(evalc("disp([bRets.Properties.VariableNames' num2cell(SR)])"), strcat("output/", backtestIdentifier, 'sharpe_ratios.txt'));



% Strategy Returns Summary
disp(' ');
disp("    Strategy Returns Summary");
disp("    -------------------------------------");
disp(libdata.summaryStats(bRets, frequency));

% log to file
log.writeTo(evalc("disp(libdata.summaryStats(bRets, frequency))"), strcat("output/", backtestIdentifier, 'strategy_returns_summary.txt'));




% ----------------------- PLOTS ---------------------------

libvis = libvisualize();
libcolors = libcolors();




if strcmp(datasetName, 'lecture')
    % plot returns of asset classes in grid
    titleStr = 'Asset class returns';
    f = libvis.newFigure(titleStr, 400, 40, 1600, 900);
    t = tiledlayout(3, 2, 'Padding','compact');
    ylabel(t, 'log-returns [%]')
    nexttile; libvis.plotReturns('Cash', cumRets(:, 1), [], '', @libcolors.distinctColors)
    nexttile; libvis.plotReturns('Bonds', cumRets(:, 2:6), [], '', @libcolors.distinctColors)
    nexttile; libvis.plotReturns('Equities', cumRets(:, 7:10), [], '', @libcolors.distinctColors)
    nexttile; libvis.plotReturns('Alternative', cumRets(:, 11:12), [], '', @libcolors.distinctColors)
    nexttile; libvis.plotReturns('Commodities', cumRets(:, 14), [], '', @libcolors.distinctColors)
    nexttile; libvis.plotReturns('ILS', cumRets(:, 13), [], '', @libcolors.distinctColors)
else
    % plot returns of asset classes in one plot
    titleStr = 'Asset class returns';
    f = libvis.newFigure(titleStr, 400, 40, 1600, 900);
    tiledlayout(1, 1, 'Padding','compact');
    nexttile; libvis.plotReturns(titleStr, cumRets, [], 'log-returns [%]', @libcolors.gradientColors)
end

% print to PDF
libvis.setPrintOptions(gcf);
libvis.printFigure(gcf, sprintf("output/dataset=%s-asset_class_returns.pdf", datasetName));





% plot strategy returns
bCumRets = libdata.cumulativeReturns(bRets);

titleStr = 'Strategy Cumulative Returns';
f = libvis.newFigure(titleStr, 400, 40, 1600, 900);
tiledlayout(1, 1, 'Padding','compact');
labels = strcat(num2str(SR, "SR=%.2f - "), " ", bCumRets.Properties.VariableNames');
nexttile; libvis.plotReturns(titleStr, bCumRets, labels, 'log-returns [%]', @libcolors.distinctColors)

% print to PDF
libvis.setPrintOptions(gcf);
libvis.printFigure(gcf, strcat("output/", backtestIdentifier, 'strategy_cum_rets.pdf'));




% strategy weights over time (without price change effect)
f = libvis.newFigure('Allocation Strategy', 400, 40, 1600, 900);
tiledlayout(length(bRes), 1, 'Padding','compact');
for i=1:length(bRes)
    plotTitle = strcat("Strategy Allocation - ", bRes{i}.Config.Label);
    wgts = bRes{i}.StrategyWgts(bRes{i}.Config.StartIndex:end, :);
    
    labels = [];
    if i == 1
        labels = wgts.Properties.VariableNames;
    end
    
    nexttile;
    libvis.plotWeights(plotTitle, wgts, labels, 'Weight [%]', @libcolors.gradientColors);
end

% print to PDF
libvis.setPrintOptions(gcf);
print(gcf, '-dpdf', '-painters', strcat("output/", backtestIdentifier, 'strategy_allocation.pdf'));




% portfolio weights over time (including price change effect)
f = libvis.newFigure('Allocation Portfolio', 400, 40, 1600, 900);
tiledlayout(length(bRes), 1, 'Padding','compact');
for i=1:length(bRes)
    plotTitle = strcat("Portfolio Allocation - ", bRes{i}.Config.Label);
    wgts = bRes{i}.PortfolioWgts(bRes{i}.Config.StartIndex:end, :);
    
    labels = [];
    if i == 1
        labels = wgts.Properties.VariableNames;
    end
    
    nexttile;
    libvis.plotWeights(plotTitle, wgts, labels, 'Weight [%]', @libcolors.gradientColors);
end

% print to PDF
libvis.setPrintOptions(gcf);
print(gcf, '-dpdf', '-painters', strcat("output/", backtestIdentifier, 'portfolio_allocation.pdf'));




% portfolio weights boxplots
f = libvis.newFigure('Weights Boxplot Strategy', 400, 40, 1600, 900);
[x, y] = libvis.calcGridSize(length(bRes));
tiledlayout(y, x, 'Padding','compact');
for i=1:length(bRes)
    wgts = bRes{i}.PortfolioWgts(bRes{i}.Config.StartIndex:end, :);
    
    % boxplot
    nexttile;
    boxplot(table2array(wgts) * 100);
    
    % axis ranges
    ylim([0 100])
    
    % title
    title(bRes{i}.Config.Label)
    
    % y-axis label
    ylabel('Weight [%]')
    set(gca, 'YTick', 0:20:100)
end

% print to PDF
libvis.setPrintOptions(gcf);
print(gcf, '-dpdf', '-painters', strcat("output/", backtestIdentifier, 'strategy_weights_boxplot.pdf'));




% risk contribution over time
f = libvis.newFigure('Risk Contribution Strategy', 400, 40, 1600, 900);
tiledlayout(length(bRes), 1, 'Padding','compact');
for i=1:length(bRes)
    plotTitle = bRes{i}.Config.Label;
    ctb = bRes{i}.RiskCtb(bRes{i}.Config.StartIndex:end, :);
    
    labels = [];
    if i == 1
        labels = wgts.Properties.VariableNames;
    end
    
    nexttile;
    libvis.plotWeights(plotTitle, ctb, labels, 'Weight [%]', @libcolors.gradientColors);
end

% print to PDF
libvis.setPrintOptions(gcf);
print(gcf, '-dpdf', '-painters', strcat("output/", backtestIdentifier, 'strategy_risk_ctb.pdf'));



% risk contribution boxplots
f = libvis.newFigure('Risk Contribution Boxplot Strategy', 400, 40, 1600, 900);
[x, y] = libvis.calcGridSize(length(bRes));
tiledlayout(y, x, 'Padding','compact');
for i=1:length(bRes)
    ctb = bRes{i}.RiskCtb(bRes{i}.Config.StartIndex:end, :);
    
    % boxplot
    nexttile;
    boxplot(table2array(ctb) * 100);
    
    % axis ranges
    ylim([0 100])
    
    % title
    title(bRes{i}.Config.Label)
    
    % y-axis label
    ylabel('Weight [%]')
    set(gca, 'YTick', 0:20:100)
end

% print to PDF
libvis.setPrintOptions(gcf);
print(gcf, '-dpdf', '-painters', strcat("output/", backtestIdentifier, 'strategy_risk_ctb_boxplot.pdf'));



