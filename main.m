clc; clear; close all force;

addpath('classes');

% load data
libdata = libdata();

% lecture dataset
[lecRets, frequency] = libdata.readLectureDataset();
rets = lecRets;

% data summary statistics
libdata.summaryStats(rets, frequency)



% backtest
librets = libreturns();
libcov = libcovariance();
libopt = liboptimizer();

estimationWindow = 2 * frequency;
optimizationInterval = 0.25 * frequency;
rebalancingInterval = 0.25 * frequency;
startIndex = estimationWindow + 1;

movingWndDataFunc = @(rets, idx) libdata.extractWindow(rets, idx, estimationWindow);
movingWndFutureDataFunc = @(rets, idx) libdata.extractWindow(rets, idx + estimationWindow, estimationWindow);


% 1/N
EQW = BacktestConfig('1/N');
EQW.ExpectedRetsFunc = @librets.expMovingAverage;
EQW.ExpectedRetsDataFunc = movingWndDataFunc;
EQW.CovFunc = @libcov.sampleCovShrinkageOAS;
EQW.CovDataFunc = movingWndDataFunc;
EQW.PortOptimizerFunc = @libopt.EqualWeights;
EQW.OptimizationInterval = optimizationInterval;
EQW.RebalancingInterval = rebalancingInterval;
EQW.Returns = rets;
EQW.Securities = rets.Properties.VariableNames;
EQW.StartIndex = startIndex;

% Minimum Variance
MinVar = BacktestConfig('Minimum Variance');
MinVar.ExpectedRetsFunc = @librets.expMovingAverage;
MinVar.ExpectedRetsDataFunc = movingWndDataFunc;
MinVar.CovFunc = @libcov.sampleCovShrinkageOAS;
MinVar.CovDataFunc = movingWndDataFunc;
MinVar.PortOptimizerFunc = @libopt.MinVariance;
MinVar.OptimizationInterval = optimizationInterval;
MinVar.RebalancingInterval = rebalancingInterval;
MinVar.Returns = rets;
MinVar.Securities = rets.Properties.VariableNames;
MinVar.StartIndex = startIndex;

% Maximum Sharpe Ratio
MSR = BacktestConfig('Maximum Sharpe Ratio');
MSR.ExpectedRetsFunc = @librets.expMovingAverage;
MSR.ExpectedRetsDataFunc = movingWndDataFunc;
MSR.CovFunc = @libcov.sampleCovShrinkageOAS;
MSR.CovDataFunc = movingWndDataFunc;
MSR.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSR.OptimizationInterval = optimizationInterval;
MSR.RebalancingInterval = rebalancingInterval;
MSR.Returns = rets;
MSR.Securities = rets.Properties.VariableNames;
MSR.StartIndex = startIndex;

% Maximum SR (perfect information)
MSRP = BacktestConfig('Maximum Sharpe Ratio (perfect information)');
MSRP.ExpectedRetsFunc = @librets.arithmeticMean;
MSRP.ExpectedRetsDataFunc = movingWndFutureDataFunc;
MSRP.CovFunc = @libcov.sampleCovShrinkageOAS;
MSRP.CovDataFunc = movingWndFutureDataFunc;
MSRP.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSRP.OptimizationInterval = optimizationInterval;
MSRP.RebalancingInterval = rebalancingInterval;
MSRP.Returns = rets;
MSRP.Securities = rets.Properties.VariableNames;
MSRP.StartIndex = startIndex;

% Equal Risk Contribution
ERC = BacktestConfig('Equal Risk Contribution');
ERC.ExpectedRetsFunc = @librets.expMovingAverage;
ERC.ExpectedRetsDataFunc = movingWndDataFunc;
ERC.CovFunc = @libcov.sampleCovShrinkageOAS;
ERC.CovDataFunc = movingWndDataFunc;
ERC.PortOptimizerFunc = @libopt.EqualRiskContribution;
ERC.OptimizationInterval = optimizationInterval;
ERC.RebalancingInterval = rebalancingInterval;
ERC.Returns = rets;
ERC.Securities = rets.Properties.VariableNames;
ERC.StartIndex = startIndex;

% list of backtest configs
% bCfg = {EQW, MinVar, ERC, MSR, MSRP};
bCfg = {EQW, MinVar, ERC, MSR};
% bCfg = {EQW, MinVar};
% bCfg = {ERC};



% run backtests in parallel
bRes = {};
parfor i=1:length(bCfg)
%for i=1:length(bCfg)
    bRes{i} = libbacktest().execute(bCfg{i});
end


% store backtest portfolio returns in one timetable
bRets = timetable(rets.Date);
bRets.Properties.DimensionNames = {'Date', 'Returns'};

for i=1:length(bCfg)
    bRets = addvars(bRets, bRes{i}.PortfolioRets{:, 1}, 'NewVariableNames', bCfg{i}.Name);
end


% Sharpe ratios
SR = libdata.sharpeRatio(bRets, frequency);
disp(' ');
disp("    Portfolio Sharpe Ratios");
disp("    -------------------------------------");
disp([bRets.Properties.VariableNames' num2cell(SR)]);
disp(' ');




% ----------------------- PLOTS ---------------------------

libvis = libvisualize();
libcolors = libcolors();

% strategy weights over time
libvis.newFigure('Strategy Allocations', true);
tiledlayout(length(bRes), 1, 'Padding','compact');
for i=1:length(bRes)
    plotTitle = strcat("Strategy Allocation - ", bRes{i}.Config.Name);
    wgts = bRes{i}.StrategyWgts(bRes{i}.Config.StartIndex:end, :);
    
    labels = [];
    if i == 1
        labels = wgts.Properties.VariableNames;
    end
    
    nexttile;
    libvis.plotWeights(plotTitle, wgts, labels, 'log-returns [%]', @libcolors.gradientColors);
end




% portfolio weights over time
libvis.newFigure('Portfolio Allocations', true);
tiledlayout(length(bRes), 1, 'Padding','compact');
for i=1:length(bRes)
    plotTitle = strcat("Portfolio Allocation - ", bRes{i}.Config.Name);
    wgts = bRes{i}.PortfolioWgts(bRes{i}.Config.StartIndex:end, :);
    
    labels = [];
    if i == 1
        labels = wgts.Properties.VariableNames;
    end
    
    nexttile;
    libvis.plotWeights(plotTitle, wgts, labels, 'log-returns [%]', @libcolors.gradientColors);
end








% plot strategy returns
bCumRets = libdata.cumulativeReturns(bRets);

titleStr = 'Strategy Cumulative Returns';
libvis.newFigure(titleStr, false);
tiledlayout(1, 1, 'Padding','compact');
labels = strcat(num2str(SR, "SR=%.2f - "), " ", bCumRets.Properties.VariableNames');
nexttile; libvis.plotReturns(titleStr, bCumRets, labels, 'log-returns [%]', @libcolors.distinctColors)



% % plot returns of asset classes in different plots
% titleStr = 'Asset class returns';
% libvis.newFigure(titleStr, true);
% t = tiledlayout(3, 2, 'Padding','compact');
% ylabel(t, 'log-returns [%]')
% cumRets = libdata.cumulativeReturns(rets);
% nexttile; libvis.plotReturns('Cash', cumRets(:, 1), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Bonds', cumRets(:, 2:6), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Equities', cumRets(:, 7:10), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Alternative', cumRets(:, 11:13), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Liability', cumRets(:, 15:18), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Commodities', cumRets(:, 14), [], '', @libcolors.distinctColors)
% 
% 
% % plot returns of asset classes in one plot
% titleStr = 'Asset class returns';
% libvis.newFigure(titleStr, true);
% libvis.plotReturns(titleStr, cumRets, [], 'log-returns [%]', @libcolors.gradientColors)





% % visualize a matrix and it's values
% A = nancov(rets{:,:}) * 1000000;
% n = size(A, 1);
% m = size(A, 2);
% cmap = autumn(ceil(max(max(A))));
% 
% figure
% image(A)
% colormap(cmap)
% set(gca,'XTick',[],'YTick',[],'YDir','normal')
% [x,y] = meshgrid(1:n,1:m);
% text(x(:),y(:),num2str(A(:)),'HorizontalAlignment','center')



