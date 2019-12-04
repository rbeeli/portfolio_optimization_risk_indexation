clc; clear; close all force;

addpath('classes');

% load data
libdata = libdata();

% lecture dataset
[lecRets, frequency] = libdata.readLectureDataset();
rets = lecRets;
nAssets = size(rets, 2);

% Strategic Asset Allocation
SAA = libdata.readSAA();

% data summary statistics
cumRets = libdata.cumulativeReturns(rets);
libdata.summaryStats(rets, frequency)



% backtest
librets = libreturns();
libcov = libcovariance();
libopt = liboptimizer();
libconst = libconstraints();

estimationWindow = 3 * frequency;
optimizationInterval = 0.5 * frequency;
rebalancingInterval = 0.5 * frequency;
startIndex = estimationWindow + 1;

movingWndDataFunc = @(rets, idx) libdata.extractWindow(rets, idx, estimationWindow);
movingWndFutureDataFunc = @(rets, idx) libdata.extractWindow(rets, idx + estimationWindow, estimationWindow);


EQW = BacktestConfig('1/N');
EQW.ExpectedRetsDataFunc = movingWndDataFunc;
EQW.CovDataFunc = movingWndDataFunc;
EQW.PortOptimizerFunc = @libopt.EqualWeights;
EQW.OptimizationInterval = optimizationInterval;
EQW.RebalancingInterval = rebalancingInterval;
EQW.Returns = rets;
EQW.Securities = rets.Properties.VariableNames;
EQW.StartIndex = startIndex;

MinVar = BacktestConfig('Minimum Variance (unconstrained)');
MinVar.ExpectedRetsFunc = @librets.expMovingAverage;
MinVar.ExpectedRetsDataFunc = movingWndDataFunc;
MinVar.CovFunc = @libcov.sampleCov;
MinVar.CovDataFunc = movingWndDataFunc;
MinVar.PortOptimizerFunc = @libopt.MinVariance;
MinVar.OptimizationInterval = optimizationInterval;
MinVar.RebalancingInterval = rebalancingInterval;
MinVar.Returns = rets;
MinVar.Securities = rets.Properties.VariableNames;
MinVar.StartIndex = startIndex;

MinVar2 = BacktestConfig('Minimum Variance (shrinkage, unconstrained)');
MinVar2.ExpectedRetsFunc = @librets.expMovingAverage;
MinVar2.ExpectedRetsDataFunc = movingWndDataFunc;
MinVar2.CovFunc = @libcov.sampleCovShrinkageOAS;
MinVar2.CovDataFunc = movingWndDataFunc;
MinVar2.PortOptimizerFunc = @libopt.MinVariance;
MinVar2.OptimizationInterval = optimizationInterval;
MinVar2.RebalancingInterval = rebalancingInterval;
MinVar2.Returns = rets;
MinVar2.Securities = rets.Properties.VariableNames;
MinVar2.StartIndex = startIndex;

MinVar3 = BacktestConfig('Minimum Variance (shrinkage, SAA)');
MinVar3.ExpectedRetsFunc = @librets.expMovingAverage;
MinVar3.ExpectedRetsDataFunc = movingWndDataFunc;
MinVar3.CovFunc = @libcov.sampleCovShrinkageOAS;
MinVar3.CovDataFunc = movingWndDataFunc;
MinVar3.PortOptimizerFunc = @libopt.MinVarianceConstrained;
MinVar3.ConstraintsFunc = @(optParams) libconst.imposeSAAPositionLevel(optParams, SAA);
MinVar3.OptimizationInterval = optimizationInterval;
MinVar3.RebalancingInterval = rebalancingInterval;
MinVar3.Returns = rets;
MinVar3.Securities = rets.Properties.VariableNames;
MinVar3.StartIndex = startIndex;

MSR = BacktestConfig('Maximum Sharpe Ratio');
MSR.ExpectedRetsFunc = @librets.expMovingAverage;
MSR.ExpectedRetsDataFunc = movingWndDataFunc;
MSR.CovFunc = @libcov.sampleCov;
MSR.CovDataFunc = movingWndDataFunc;
MSR.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSR.OptimizationInterval = optimizationInterval;
MSR.RebalancingInterval = rebalancingInterval;
MSR.Returns = rets;
MSR.Securities = rets.Properties.VariableNames;
MSR.StartIndex = startIndex;

MSR2 = BacktestConfig('Maximum Sharpe Ratio (shrinkage)');
MSR2.ExpectedRetsFunc = @librets.expMovingAverage;
MSR2.ExpectedRetsDataFunc = movingWndDataFunc;
MSR2.CovFunc = @libcov.sampleCovShrinkageOAS;
MSR2.CovDataFunc = movingWndDataFunc;
MSR2.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSR2.OptimizationInterval = optimizationInterval;
MSR2.RebalancingInterval = rebalancingInterval;
MSR2.Returns = rets;
MSR2.Securities = rets.Properties.VariableNames;
MSR2.StartIndex = startIndex;

MSRP = BacktestConfig('Maximum Sharpe Ratio (perfect information)');
MSRP.ExpectedRetsFunc = @librets.arithmeticMean;
MSRP.ExpectedRetsDataFunc = movingWndFutureDataFunc;
MSRP.CovFunc = @libcov.sampleCov;
MSRP.CovDataFunc = movingWndFutureDataFunc;
MSRP.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSRP.OptimizationInterval = optimizationInterval;
MSRP.RebalancingInterval = rebalancingInterval;
MSRP.Returns = rets;
MSRP.Securities = rets.Properties.VariableNames;
MSRP.StartIndex = startIndex;

MSRP2 = BacktestConfig('Maximum Sharpe Ratio (perfect information, shrinkage)');
MSRP2.ExpectedRetsFunc = @librets.arithmeticMean;
MSRP2.ExpectedRetsDataFunc = movingWndFutureDataFunc;
MSRP2.CovFunc = @libcov.sampleCovShrinkageOAS;
MSRP2.CovDataFunc = movingWndFutureDataFunc;
MSRP2.PortOptimizerFunc = @libopt.MaxSharpeRatio;
MSRP2.OptimizationInterval = optimizationInterval;
MSRP2.RebalancingInterval = rebalancingInterval;
MSRP2.Returns = rets;
MSRP2.Securities = rets.Properties.VariableNames;
MSRP2.StartIndex = startIndex;

ERC = BacktestConfig('Equal Risk Contribution');
ERC.ExpectedRetsFunc = @librets.expMovingAverage;
ERC.ExpectedRetsDataFunc = movingWndDataFunc;
ERC.CovFunc = @libcov.sampleCov;
ERC.CovDataFunc = movingWndDataFunc;
ERC.PortOptimizerFunc = @libopt.EqualRiskContribution;
ERC.OptimizationInterval = optimizationInterval;
ERC.RebalancingInterval = rebalancingInterval;
ERC.Returns = rets;
ERC.Securities = rets.Properties.VariableNames;
ERC.StartIndex = startIndex;

ERC2 = BacktestConfig('Equal Risk Contribution (shrinkage)');
ERC2.ExpectedRetsFunc = @librets.expMovingAverage;
ERC2.ExpectedRetsDataFunc = movingWndDataFunc;
ERC2.CovFunc = @libcov.sampleCovShrinkageOAS;
ERC2.CovDataFunc = movingWndDataFunc;
ERC2.PortOptimizerFunc = @libopt.EqualRiskContribution;
ERC2.OptimizationInterval = optimizationInterval;
ERC2.RebalancingInterval = rebalancingInterval;
ERC2.Returns = rets;
ERC2.Securities = rets.Properties.VariableNames;
ERC2.StartIndex = startIndex;

% list of backtest configs
%bCfg = {MinVar, MinVar2, MSR, MSR2, MSRP, MSRP2};
bCfg = {MinVar3, MinVar2, EQW};
%bCfg = {MinVar2};



% run backtests in parallel
bRes = {};
%parfor i=1:length(bCfg)
for i=1:length(bCfg)
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
% nexttile; libvis.plotReturns('Cash', cumRets(:, 1), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Bonds', cumRets(:, 2:6), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Equities', cumRets(:, 7:10), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Alternative', cumRets(:, 11:13), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Liability', cumRets(:, 15:18), [], '', @libcolors.distinctColors)
% nexttile; libvis.plotReturns('Commodities', cumRets(:, 14), [], '', @libcolors.distinctColors)


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



