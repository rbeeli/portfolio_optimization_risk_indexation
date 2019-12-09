% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

% clear variables and command window
clc; clear;

% import all classes
addpath('classes');

% import all library objects
lData = libdata();
lRets = libreturns();
lCov = libcovariance();
lOpt = liboptimizer();
lConst = libconstraints();


% use parallel processing of backtest (parfor)
parallel = true;

% ----------------------------------------------
% data
% ----------------------------------------------

% % Dow Jones Industrial Average 30
% [datasetName, rets, frequency] = lData.readDJIA30Dataset();

% % lecture dataset
% [datasetName, rets, frequency] = lData.readLectureDataset();

% lecture dataset w/o `Cash CHF`
[datasetName, rets, frequency] = lData.readLectureNoCashDataset();

% Strategic Asset Allocation
SAA = lData.readSAA();


% ----------------------------------------------
% backtest
% ----------------------------------------------
estimationWindow = 4 * frequency;
optimizationInterval = 0.5 * frequency;
rebalancingInterval = 0.5 * frequency;
startIndex = estimationWindow + 1;

% moving window data extraction functions
movingWndDataFunc = @(rets, idx) lData.extractWindow(rets, idx, estimationWindow);
movingWndFutureDataFunc = @(rets, idx) lData.extractWindow(rets, idx + estimationWindow, estimationWindow);

maxWeight = 0.20;

% unique identifier of backtest, used for filename of plots/results in folder `output`
backtestId = sprintf('dataset=%s,wnd=%.1fyrs,opt.int.=%.1fyrs,max.wgt=%.2f,freq=%.0f_', datasetName, estimationWindow / frequency, optimizationInterval / frequency, maxWeight, frequency);



EQW = BacktestConfig('EQW', '1/N');
EQW.ExpectedRetsDataFunc = movingWndDataFunc;
EQW.CovFunc = @lCov.sampleCov;
EQW.CovDataFunc = movingWndDataFunc;
EQW.PortOptimizerFunc = @lOpt.EqualWeights;
EQW.OptimizationInterval = optimizationInterval;
EQW.RebalancingInterval = rebalancingInterval;
EQW.StartIndex = startIndex;

MVAR = BacktestConfig('MVAR', 'Minimum Variance');
MVAR.ExpectedRetsFunc = @lRets.simpleMean;
MVAR.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR.CovFunc = @lCov.sampleCov;
MVAR.CovDataFunc = movingWndDataFunc;
MVAR.PortOptimizerFunc = @lOpt.MinVariance;
MVAR.ConstraintsFunc = @lConst.defaultConstraints;
MVAR.OptimizationInterval = optimizationInterval;
MVAR.RebalancingInterval = rebalancingInterval;
MVAR.StartIndex = startIndex;

MVAR_shrink = BacktestConfig('MVAR_shr', 'Minimum Variance (shrinkage)');
MVAR_shrink.ExpectedRetsFunc = @lRets.simpleMean;
MVAR_shrink.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR_shrink.CovFunc = @lCov.sampleCovShrinkageOAS;
MVAR_shrink.CovDataFunc = movingWndDataFunc;
MVAR_shrink.PortOptimizerFunc = @lOpt.MinVariance;
MVAR_shrink.ConstraintsFunc = @lConst.defaultConstraints;
MVAR_shrink.OptimizationInterval = optimizationInterval;
MVAR_shrink.RebalancingInterval = rebalancingInterval;
MVAR_shrink.StartIndex = startIndex;

MVAR_shrink_fixed_const = BacktestConfig('MVAR_shr_fix', sprintf('Minimum Variance (shrinkage, %.0f%% max weight)', maxWeight*100));
MVAR_shrink_fixed_const.ExpectedRetsFunc = @lRets.simpleMean;
MVAR_shrink_fixed_const.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR_shrink_fixed_const.CovFunc = @lCov.sampleCovShrinkageOAS;
MVAR_shrink_fixed_const.CovDataFunc = movingWndDataFunc;
MVAR_shrink_fixed_const.PortOptimizerFunc = @lOpt.MinVariance;
MVAR_shrink_fixed_const.ConstraintsFunc = @(optParams) lConst.equalMaxWeight(optParams, maxWeight);
MVAR_shrink_fixed_const.OptimizationInterval = optimizationInterval;
MVAR_shrink_fixed_const.RebalancingInterval = rebalancingInterval;
MVAR_shrink_fixed_const.StartIndex = startIndex;

MVAR_shrink_SAA = BacktestConfig('MVAR_shr_SAA', 'Minimum Variance (shrinkage, SAA)');
MVAR_shrink_SAA.ExpectedRetsFunc = @lRets.simpleMean;
MVAR_shrink_SAA.ExpectedRetsDataFunc = movingWndDataFunc;
MVAR_shrink_SAA.CovFunc = @lCov.sampleCovShrinkageOAS;
MVAR_shrink_SAA.CovDataFunc = movingWndDataFunc;
MVAR_shrink_SAA.PortOptimizerFunc = @lOpt.MinVariance;
MVAR_shrink_SAA.ConstraintsFunc = @(optParams) lConst.imposeSAAonAssetClasses(optParams, SAA, maxWeight);
MVAR_shrink_SAA.OptimizationInterval = optimizationInterval;
MVAR_shrink_SAA.RebalancingInterval = rebalancingInterval;
MVAR_shrink_SAA.StartIndex = startIndex;

MSR_SMA = BacktestConfig('MSR', 'Maximum Sharpe Ratio');
MSR_SMA.ExpectedRetsFunc = @lRets.simpleMean;
MSR_SMA.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_SMA.CovFunc = @lCov.sampleCov;
MSR_SMA.CovDataFunc = movingWndDataFunc;
MSR_SMA.PortOptimizerFunc = @lOpt.MaxSharpeRatio;
MSR_SMA.ConstraintsFunc = @lConst.defaultConstraints;
MSR_SMA.OptimizationInterval = optimizationInterval;
MSR_SMA.RebalancingInterval = rebalancingInterval;
MSR_SMA.StartIndex = startIndex;

MSR_SMA_shrink = BacktestConfig('MSR_shr', 'Maximum Sharpe Ratio (shrinkage)');
MSR_SMA_shrink.ExpectedRetsFunc = @lRets.simpleMean;
MSR_SMA_shrink.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_SMA_shrink.CovFunc = @lCov.sampleCovShrinkageOAS;
MSR_SMA_shrink.CovDataFunc = movingWndDataFunc;
MSR_SMA_shrink.PortOptimizerFunc = @lOpt.MaxSharpeRatio;
MSR_SMA_shrink.ConstraintsFunc = @lConst.defaultConstraints;
MSR_SMA_shrink.OptimizationInterval = optimizationInterval;
MSR_SMA_shrink.RebalancingInterval = rebalancingInterval;
MSR_SMA_shrink.StartIndex = startIndex;

MSR_shrink_fixed_const = BacktestConfig('MSR_shr_fix', sprintf('Maximum Sharpe Ratio (shrinkage, %.0f%% max weight)', maxWeight*100));
MSR_shrink_fixed_const.ExpectedRetsFunc = @lRets.simpleMean;
MSR_shrink_fixed_const.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_shrink_fixed_const.CovFunc = @lCov.sampleCovShrinkageOAS;
MSR_shrink_fixed_const.CovDataFunc = movingWndDataFunc;
MSR_shrink_fixed_const.PortOptimizerFunc = @lOpt.MaxSharpeRatio;
MSR_shrink_fixed_const.ConstraintsFunc = @(optParams) lConst.equalMaxWeight(optParams, maxWeight);
MSR_shrink_fixed_const.OptimizationInterval = optimizationInterval;
MSR_shrink_fixed_const.RebalancingInterval = rebalancingInterval;
MSR_shrink_fixed_const.StartIndex = startIndex;

MSR_shrink_SAA = BacktestConfig('MSR_shr_SAA', 'Maximum Sharpe Ratio (shrinkage, SAA)');
MSR_shrink_SAA.ExpectedRetsFunc = @lRets.simpleMean;
MSR_shrink_SAA.ExpectedRetsDataFunc = movingWndDataFunc;
MSR_shrink_SAA.CovFunc = @lCov.sampleCovShrinkageOAS;
MSR_shrink_SAA.CovDataFunc = movingWndDataFunc;
MSR_shrink_SAA.PortOptimizerFunc = @lOpt.MaxSharpeRatio;
MSR_shrink_SAA.ConstraintsFunc = @(optParams) lConst.imposeSAAonAssetClasses(optParams, SAA, maxWeight);
MSR_shrink_SAA.OptimizationInterval = optimizationInterval;
MSR_shrink_SAA.RebalancingInterval = rebalancingInterval;
MSR_shrink_SAA.StartIndex = startIndex;

MSRP_SMA = BacktestConfig('MSRP', 'Maximum Sharpe Ratio (perfect information)');
MSRP_SMA.ExpectedRetsFunc = @lRets.simpleMean;
MSRP_SMA.ExpectedRetsDataFunc = movingWndFutureDataFunc;
MSRP_SMA.CovFunc = @lCov.sampleCov;
MSRP_SMA.CovDataFunc = movingWndFutureDataFunc;
MSRP_SMA.PortOptimizerFunc = @lOpt.MaxSharpeRatio;
MSRP_SMA.ConstraintsFunc = @lConst.defaultConstraints;
MSRP_SMA.OptimizationInterval = optimizationInterval;
MSRP_SMA.RebalancingInterval = rebalancingInterval;
MSRP_SMA.StartIndex = startIndex;

MSRP_SMA_shrink = BacktestConfig('MSRP_shr', 'Maximum Sharpe Ratio (perfect information, shrinkage)');
MSRP_SMA_shrink.ExpectedRetsFunc = @lRets.simpleMean;
MSRP_SMA_shrink.ExpectedRetsDataFunc = movingWndFutureDataFunc;
MSRP_SMA_shrink.CovFunc = @lCov.sampleCovShrinkageOAS;
MSRP_SMA_shrink.CovDataFunc = movingWndFutureDataFunc;
MSRP_SMA_shrink.PortOptimizerFunc = @lOpt.MaxSharpeRatio;
MSRP_SMA_shrink.ConstraintsFunc = @lConst.defaultConstraints;
MSRP_SMA_shrink.OptimizationInterval = optimizationInterval;
MSRP_SMA_shrink.RebalancingInterval = rebalancingInterval;
MSRP_SMA_shrink.StartIndex = startIndex;

ERC = BacktestConfig('ERC', 'Equal Risk Contribution');
ERC.ExpectedRetsFunc = @lRets.simpleMean;
ERC.ExpectedRetsDataFunc = movingWndDataFunc;
ERC.CovFunc = @lCov.sampleCov;
ERC.CovDataFunc = movingWndDataFunc;
ERC.PortOptimizerFunc = @lOpt.EqualRiskContribution;
ERC.ConstraintsFunc = @lConst.defaultConstraints;
ERC.OptimizationInterval = optimizationInterval;
ERC.RebalancingInterval = rebalancingInterval;
ERC.StartIndex = startIndex;

ERC_shrink = BacktestConfig('ERC_shr', 'Equal Risk Contribution (shrinkage)');
ERC_shrink.ExpectedRetsFunc = @lRets.simpleMean;
ERC_shrink.ExpectedRetsDataFunc = movingWndDataFunc;
ERC_shrink.CovFunc = @lCov.sampleCovShrinkageOAS;
ERC_shrink.CovDataFunc = movingWndDataFunc;
ERC_shrink.PortOptimizerFunc = @lOpt.EqualRiskContribution;
ERC_shrink.ConstraintsFunc = @lConst.defaultConstraints;
ERC_shrink.OptimizationInterval = optimizationInterval;
ERC_shrink.RebalancingInterval = rebalancingInterval;
ERC_shrink.StartIndex = startIndex;

ERC_shrink_fixed_const = BacktestConfig('ERC_shr_fix', sprintf('Equal Risk Contribution (shrinkage, %.0f%% max weight)', maxWeight*100));
ERC_shrink_fixed_const.ExpectedRetsFunc = @lRets.simpleMean;
ERC_shrink_fixed_const.ExpectedRetsDataFunc = movingWndDataFunc;
ERC_shrink_fixed_const.CovFunc = @lCov.sampleCovShrinkageOAS;
ERC_shrink_fixed_const.CovDataFunc = movingWndDataFunc;
ERC_shrink_fixed_const.PortOptimizerFunc = @lOpt.EqualRiskContribution;
ERC_shrink_fixed_const.ConstraintsFunc = @(optParams) lConst.equalMaxWeight(optParams, maxWeight);
ERC_shrink_fixed_const.OptimizationInterval = optimizationInterval;
ERC_shrink_fixed_const.RebalancingInterval = rebalancingInterval;
ERC_shrink_fixed_const.StartIndex = startIndex;

ERC_shrink_SAA = BacktestConfig('ERC_shr_SAA', 'Equal Risk Contribution (shrinkage, SAA)');
ERC_shrink_SAA.ExpectedRetsFunc = @lRets.simpleMean;
ERC_shrink_SAA.ExpectedRetsDataFunc = movingWndDataFunc;
ERC_shrink_SAA.CovFunc = @lCov.sampleCovShrinkageOAS;
ERC_shrink_SAA.CovDataFunc = movingWndDataFunc;
ERC_shrink_SAA.PortOptimizerFunc = @lOpt.EqualRiskContribution;
ERC_shrink_SAA.ConstraintsFunc = @(optParams) lConst.imposeSAAonAssetClasses(optParams, SAA, maxWeight);
ERC_shrink_SAA.OptimizationInterval = optimizationInterval;
ERC_shrink_SAA.RebalancingInterval = rebalancingInterval;
ERC_shrink_SAA.StartIndex = startIndex;





% ------------------------------------
% list of various backtest configs
% ------------------------------------

% conductBacktest(parallel, 'test', { ERC, ERC_shrink }, rets, frequency, datasetName);

% % (1) naive approach: sample covariance, simple mean
% cfg = { MSR_SMA, MVAR, ERC };
% conductBacktest(parallel, strcat('1_', backtestId), cfg, rets, frequency, datasetName);
% 
% (2) sample covariance vs. shrinkage estimator
cfg = { MSR_SMA, MSR_SMA_shrink, MVAR, MVAR_shrink, ERC, ERC_shrink };
conductBacktest(parallel, strcat('2_', backtestId), cfg, rets, frequency, datasetName);
% 
% % (3) sample covariance vs. shrinkage estimator under perfect information
% cfg = { MSRP_SMA, MSRP_SMA_shrink };
% conductBacktest(parallel, strcat('3_', backtestId), cfg, rets, frequency, datasetName);
% 
% % (4) where we are now - different methods
% cfg = { EQW, MVAR_shrink, MSR_SMA_shrink, ERC_shrink };
% conductBacktest(parallel, strcat('4_', backtestId), cfg, rets, frequency, datasetName);

% % % (5) unconstrained vs. fixed max. weight constraint
% % cfg = { EQW, MVAR_shrink, MVAR_shrink_fixed_const, MSR_shrink_fixed_const, ERC_shrink, ERC_shrink_fixed_const };
% % conductBacktest(parallel, strcat('5_', backtestId), cfg, rets, frequency, datasetName);

% % (6) impose SAA
% conductBacktest(parallel, strcat('6_', backtestId), { EQW, MVAR_shrink_SAA, MSR_shrink_SAA, ERC_shrink_SAA }, rets, frequency, datasetName);



function conductBacktest(parallel, backtestId, backtestCfgs, rets, frequency, datasetName)
    data = libdata();
    log = liblog();
    vis = libvis();
    colors = libcolors();

    % close all plots
    close all force;
     
    % set data for backtest configs
    for i=1:length(backtestCfgs)
        backtestCfgs{i}.Returns = rets;
        backtestCfgs{i}.Securities = rets.Properties.VariableNames;
    end

    % run backtests in parallel
    bRes = {};

    if parallel
        parfor i=1:length(backtestCfgs)
            bRes{i} = libbacktest().execute(backtestCfgs{i});
        end
    else
        for i=1:length(backtestCfgs)
            bRes{i} = libbacktest().execute(backtestCfgs{i});
        end
    end

    % add backtest names to backtest identifier string
    for i=1:length(backtestCfgs)
        backtestId = strcat(backtestId, '[', backtestCfgs{i}.Name, ']');
    end
    backtestId = strcat(backtestId, '_');


    % store backtest portfolio returns in one timetable
    bRets = timetable(rets.Date);
    bRets.Properties.DimensionNames = {'Date', 'Returns'};

    for i=1:length(backtestCfgs)
        bRets = addvars(bRets, bRes{i}.PortfolioRets{:, 1}, 'NewVariableNames', backtestCfgs{i}.Label);
    end




    % ====================================================================================================
    % Plot charts, print summary statistics.
    % Saves text output and PDF of plots into subfolder `output`.
    % ====================================================================================================

    % ------------------ SUMMARY STATISTICS --------------------
    
    % returns data
    summary1 = log.toString(data.summaryStats(rets, frequency), true);
    disp(summary1)
    
    % log to file
    log.writeTo(summary1, sprintf("output/dataset=%s-data_summary.txt", datasetName));

    

    % strategy returns
    summary2 = log.toString(data.summaryStats(bRets, frequency), true);
    disp(summary2)
    
    % log to file
    log.writeTo(summary2, strcat("output/", backtestId, 'strategy_returns_summary.txt'));




    % ----------------------- PLOTS ---------------------------

    cumRets = data.cumulativeReturns(rets);   % cumulative returns
    SR = data.sharpeRatio(bRets, frequency);  % Sharpe ratios
    
    if strcmp(datasetName, 'lecture')
        % plot returns of asset classes in grid
        titleStr = 'Asset class returns';
        f = vis.newFigure(titleStr, 400, 40, 1600, 900);
        t = tiledlayout(3, 2, 'Padding','compact');
        ylabel(t, 'log-value (1 unit initial investment)')
        nexttile; vis.plotReturns('Cash', cumRets(:, 1), [], '', @colors.distinctColors)
        nexttile; vis.plotReturns('Bonds', cumRets(:, 2:6), [], '', @colors.distinctColors)
        nexttile; vis.plotReturns('Equities', cumRets(:, 7:10), [], '', @colors.distinctColors)
        nexttile; vis.plotReturns('Alternative', cumRets(:, 11:12), [], '', @colors.distinctColors)
        nexttile; vis.plotReturns('Commodities', cumRets(:, 14), [], '', @colors.distinctColors)
        nexttile; vis.plotReturns('ILS', cumRets(:, 13), [], '', @colors.distinctColors)
    else
        % plot returns of asset classes in one plot
        titleStr = 'Asset class returns';
        f = vis.newFigure(titleStr, 400, 40, 1600, 900);
        tiledlayout(1, 1, 'Padding','compact');
        nexttile; vis.plotReturns(titleStr, cumRets, [], 'log-value (1 unit initial investment)', @colors.gradientColors)
    end

    % print to PDF
    vis.printFigure(gcf, sprintf("output/dataset=%s-asset_class_returns.pdf", datasetName));





    % plot strategy returns
    bCumRets = data.cumulativeReturns(bRets);

    titleStr = 'Strategy Cumulative Returns';
    f = vis.newFigure(titleStr, 400, 40, 1600, 900);
    tiledlayout(1, 1, 'Padding','compact');
    labels = strcat(num2str(SR, "SR=%.2f - "), " ", bCumRets.Properties.VariableNames');
    nexttile; vis.plotReturns(titleStr, bCumRets, labels, 'log-value (1 unit initial investment)', @colors.distinctColors)

    % print to PDF
    vis.printFigure(gcf, sprintf("output/%sstrategy_cum_rets.pdf", backtestId));




    % vis weights over time (without price change effect)
    f = vis.newFigure('Strategy Allocation', 400, 40, 1600, 900);
    tiledlayout(length(bRes), 1, 'Padding','compact');
    for i=1:length(bRes)
        plotTitle = strcat("Strategy Allocation: ", bRes{i}.Config.Label);
        wgts = bRes{i}.StrategyWgts(bRes{i}.Config.StartIndex:end, :);

        labels = [];
        if i == 1
            labels = wgts.Properties.VariableNames;
        end

        nexttile;
        vis.plotWeights(plotTitle, wgts, labels, 'Weight [%]', @colors.gradientColors);
    end

    % print to PDF
    vis.printFigure(gcf, sprintf("output/%sstrategy_allocation.pdf", backtestId));




    % portfolio weights over time (including price change effect)
    f = vis.newFigure('Portfolio Allocation', 400, 40, 1600, 900);
    tiledlayout(length(bRes), 1, 'Padding','compact');
    for i=1:length(bRes)
        plotTitle = strcat("Portfolio Allocation: ", bRes{i}.Config.Label);
        wgts = bRes{i}.PortfolioWgts(bRes{i}.Config.StartIndex:end, :);

        labels = [];
        if i == 1
            labels = wgts.Properties.VariableNames;
        end

        nexttile;
        vis.plotWeights(plotTitle, wgts, labels, 'Weight [%]', @colors.gradientColors);
    end

    % print to PDF
    vis.printFigure(gcf, sprintf("output/%sportfolio_allocation.pdf", backtestId));




    % portfolio weights boxplots
    f = vis.newFigure('Boxplot Strategy Allocation', 400, 40, 1600, 900);
    [x, y] = vis.calcGridSize(length(bRes));
    tiledlayout(y, x, 'Padding','compact');
    for i=1:length(bRes)
        plotTitle = strcat("Strategy Allocation: ", bRes{i}.Config.Label);
        wgts = bRes{i}.StrategyWgts(bRes{i}.Config.StartIndex:end, :);

        % boxplot
        nexttile;
        boxplot(table2array(wgts) * 100);

        % axis ranges
        ylim([0 100])

        % title
        title(plotTitle)

        % y-axis label
        ylabel('Weight [%]')
        set(gca, 'YTick', 0:20:100)
    end

    % print to PDF
    vis.printFigure(gcf, sprintf("output/%sstrategy_weights_boxplot.pdf", backtestId));




    % risk contribution over time
    f = vis.newFigure('Risk Contribution', 400, 40, 1600, 900);
    tiledlayout(length(bRes), 1, 'Padding','compact');
    for i=1:length(bRes)
        plotTitle = strcat("Risk Contribution: ", bRes{i}.Config.Label);
        ctb = bRes{i}.RiskCtb(bRes{i}.Config.StartIndex:end, :);

        labels = [];
        if i == 1
            labels = wgts.Properties.VariableNames;
        end

        nexttile;
        vis.plotWeights(plotTitle, ctb, labels, 'Weight [%]', @colors.gradientColors);
    end

    % print to PDF
    vis.printFigure(gcf, sprintf("output/%sstrategy_risk_ctb.pdf", backtestId));



    % risk contribution boxplots
    f = vis.newFigure('Boxplot Risk Contribution', 400, 40, 1600, 900);
    [x, y] = vis.calcGridSize(length(bRes));
    tiledlayout(y, x, 'Padding','compact');
    for i=1:length(bRes)
        plotTitle = strcat("Risk Contribution: ", bRes{i}.Config.Label);
        ctb = bRes{i}.RiskCtb(bRes{i}.Config.StartIndex:end, :);

        % boxplot
        nexttile;
        boxplot(table2array(ctb) * 100);

        % axis ranges
        ylim([0 100])

        % title
        title(plotTitle)

        % y-axis label
        ylabel('Risk Contribution [%]')
        set(gca, 'YTick', 0:20:100)
    end

    % print to PDF
    vis.printFigure(gcf, sprintf("output/%sstrategy_risk_ctb_boxplot.pdf", backtestId));
end



