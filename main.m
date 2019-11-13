clc; clear; close all force;

% load data
libdata = data();


% lecture dataset
[lecRets, frequency] = libdata.read_lecture_dataset();
lecRets = removevars(lecRets, {'Cash CHF'});
simpleRets = lecRets;

% S&P 500 dataset
% [sp500IdxRets, sp500StockRets, frequency] = libdata.read_sp500_dataset();

% simpleRets = sp500StockRets;

% simpleRets = sp500IdxRets;
% simpleRets = addvars(simpleRets, nanmean(sp500StockRets{:, :}, 2), 'NewVariableNames', {'Manual EW'});

names = simpleRets.Properties.VariableNames;
cumRets = libdata.cumulative_returns(simpleRets);

% data summary statistics
libdata.summary_stats(simpleRets, cumRets, frequency)



% backtest
libbacktest = backtest();
strategies = libbacktest.strategies;

estimationPeriod = 1 * frequency; % 5 years
rebalancingInterval = 6/12 * frequency; % every 1 year



wgts = cell(1, 4);

% 1/N Equal Weighted
[wgts1, rets1, sec1] = libbacktest.backtest(strategies.EqualWeighted, simpleRets, estimationPeriod, rebalancingInterval);
cumRets1 = libdata.cumulative_returns(rets1);
wgts{1} = wgts1;

% M/V minimum variance
[wgts2, rets2, sec2] = libbacktest.backtest(strategies.MinVariance, simpleRets, estimationPeriod, rebalancingInterval);
cumRets2 = libdata.cumulative_returns(rets2);
wgts{2} = wgts2;

% Maximum Sharpe Ratio
[wgts3, rets3, sec3] = libbacktest.backtest(strategies.MaxSharpeRatio, simpleRets, estimationPeriod, rebalancingInterval);
cumRets3 = libdata.cumulative_returns(rets3);
wgts{3} = wgts3;

% Equal Risk Contribution
[wgts4, rets4, sec4] = libbacktest.backtest(strategies.EqualRiskContribution, simpleRets, estimationPeriod, rebalancingInterval);
cumRets4 = libdata.cumulative_returns(rets4);
wgts{4} = wgts4;





strategyRets = timetable(simpleRets.Date, rets1{:, 1}, rets2{:, 1}, rets3{:, 1}, rets4{:, 1});
strategyRets.Properties.DimensionNames{1} = 'Date';
strategyRets.Properties.VariableNames = {'1/N' 'M/V minimum variance' 'Maximum Sharpe Ratio' 'Equal Risk Contribution'};

strategyCumRets = timetable(simpleRets.Date, cumRets1{:, 1}, cumRets2{:, 1}, cumRets3{:, 1}, cumRets4{:, 1});
strategyCumRets.Properties.DimensionNames{1} = 'Date';
strategyCumRets.Properties.VariableNames = {'1/N' 'M/V minimum variance' 'Maximum Sharpe Ratio' 'Equal Risk Contribution'};

% Sharpe Ratios
SR = libdata.sharpe_ratio(strategyRets, frequency);
disp('Strategies Sharpe Ratios');
disp([strategyRets.Properties.VariableNames' num2cell(SR)]);




figure(1)
for i=1:size(wgts, 2)
    iWgts = wgts{i};
    plot_title = strcat("Allocation over time: ", strategyRets.Properties.VariableNames{i});
    legend_items = simpleRets.Properties.VariableNames;
    
    subplot(size(wgts, 2), 1, i);
    area(iWgts{:, :})
    legend(legend_items, 'Location', 'NorthEastOutside')
    title(plot_title)
    ylabel('Allocation')
    axis([estimationPeriod size(wgts3, 1) 0 1])
    % set(gca, 'XTick', ticks)
    % set(gca, 'XTickLabel', datestr(xTickNames,12))
end



        
        

% plot strategy returns
figure(2)
subplot(2, 1, 1); plot_returns('Strategy cumulative returns', strategyCumRets)



% plot returns of asset classes
% figure(2)
subplot(2, 1, 2); plot_returns('Asset class returns', cumRets)
% subplot(3, 2, 1); plot_returns('Cash', cumRets(:, 1))
% subplot(3, 2, 2); plot_returns('Bonds', cumRets(:, 2:6))
% subplot(3, 2, 3); plot_returns('Equities', cumRets(:, 7:10))
% subplot(3, 2, 4); plot_returns('Alternative', cumRets(:, 11:12))
% subplot(3, 2, 5); plot_returns('Commodities', cumRets(:, 13))

function plot_returns(plot_title, returns)
    semilogy(returns.Date, returns{:, :})
    title(plot_title)
    
    if size(returns, 2) < 20
        legend(returns.Properties.VariableNames, 'Interpreter','none', 'Location','NorthEastOutside')
    end
end












