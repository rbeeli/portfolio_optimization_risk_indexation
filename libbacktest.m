% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

function funcs = libbacktest()
    funcs.execute = @execute;
end


function result = execute(backtestCfg)
    fprintf("Backtesting '%s' - Starting ...\n", backtestCfg.Name);
    
    timer = tic;
    
    nReturns = size(backtestCfg.Returns, 1);
    
    % store backtest result in object
    result = BacktestResult(backtestCfg);

    % portfolio weights over time
    result.PortfolioWgts = backtestCfg.Returns;
    result.PortfolioWgts{:, :} = nan;
    
    % strategy weights over time
    result.StrategyWgts = backtestCfg.Returns;
    result.StrategyWgts{:, :} = nan;
    
    % risk contributions over time
    result.RiskCtb = backtestCfg.Returns;
    result.RiskCtb{:, :} = nan;
    
    % portfolio returns
    result.PortfolioRets = timetable(backtestCfg.Returns.Date, NaN(nReturns, 1));
    result.PortfolioRets.Properties.DimensionNames{1} = 'Date';
    result.PortfolioRets.Properties.VariableNames = {'Return'};
    
    % do backtest
    nSteps = nReturns - backtestCfg.StartIndex + 1;
    logProgressSteps = floor(nSteps / 20);
    
    for idx=backtestCfg.StartIndex:nReturns
        stepIndex = idx - backtestCfg.StartIndex;
        
        if mod(stepIndex, logProgressSteps) == 0
            fprintf("Backtesting '%s' - Progress: %.0f%%\n", backtestCfg.Name, stepIndex / nSteps * 100);
        end
        
        if mod(stepIndex, backtestCfg.OptimizationInterval) == 0
            % ---
            % optimize portfolio weights again
            % ---
            
            % extract data for estimating returns and covariance
            expectedRetsData = backtestCfg.ExpectedRetsDataFunc(backtestCfg.Returns, idx);
            covData = backtestCfg.ExpectedRetsDataFunc(backtestCfg.Returns, idx);

            % only consider assets which have no NaN data for both,
            % expected returns data and covariance data.
            securities = (sum(isnan(expectedRetsData{:, :}), 1) == 0) & (sum(isnan(covData{:, :}), 1) == 0);
            securitiesNames = expectedRetsData.Properties.VariableNames(securities);
            
            expectedRetsData = expectedRetsData{:, securities};
            covData = covData{:, securities};
            
            % estimate expected returns
            expRets = [];
            if isa(backtestCfg.ExpectedRetsFunc, 'function_handle')
                expRets = backtestCfg.ExpectedRetsFunc(expectedRetsData);
            end
            
            % estimate covariance
            covMat = backtestCfg.CovFunc(covData);
            
            % optimize portfolio/calculate weights
            opts = OptParams(securitiesNames, expRets, covMat, backtestCfg.ConstraintsFunc);
            weights = backtestCfg.PortOptimizerFunc(opts)';
            
            % ensure weights sum to 100%
            weights = weights ./ sum(weights);
            
            result.PortfolioWgts{idx, securities} = weights;
            result.StrategyWgts{idx, securities} = weights;
            
            % calculate risk contribution
            sdPortfolio = sqrt(weights * covMat * weights');
            marginalCtb = weights * covMat ./ sdPortfolio; % marginal contribution of each asset
            componentCtb = marginalCtb .* weights; % weighted marginal contributions
            componentCtb = componentCtb ./ sum(componentCtb);
            
            result.RiskCtb{idx, securities} = componentCtb;
        elseif mod(stepIndex, backtestCfg.RebalancingInterval) == 0
            % ---
            % rebalance portfolio weights to match strategy weights
            % ---
            result.StrategyWgts{idx, :} = result.StrategyWgts{idx - 1, :};
            result.PortfolioWgts{idx, :} = result.StrategyWgts{idx - 1, :};
        else
            % ---
            % no optimization/rebalancing, use previous period weights
            % ---
            result.StrategyWgts{idx, :} = result.StrategyWgts{idx - 1, :};
            result.RiskCtb{idx, :} = result.RiskCtb{idx - 1, :};
            
            % adjust portfolio weights for previous period return and rescale to sum up to 100%
            result.PortfolioWgts{idx, :} = result.PortfolioWgts{idx - 1, :} .* (1 + backtestCfg.Returns{idx, :});
            result.PortfolioWgts{idx, :} = result.PortfolioWgts{idx, :} ./ nansum(result.PortfolioWgts{idx, :});
        end
        
        % previous' period weights for current returns
        result.PortfolioRets{idx, 1} = nansum(result.PortfolioWgts{idx - 1, :} .* backtestCfg.Returns{idx, :});

        % sanity checks - ensure weights sum to 1
        %assert(abs(nansum(result.PortfolioWgts{idx, :}) - 1) < 0.0001, strcat("Portfolio weights of strategy `", backtestCfg.Name, "` must sum to 1."));
        %assert(abs(nansum(result.StrategyWgts{idx, :}) - 1) < 0.0001, strcat("Strategy weights of strategy `", backtestCfg.Name, "` must sum to 1."));
        assert(abs(sum(componentCtb) - 1) < 0.0001, 'Risk contributions must sum to 100%.');
    end
    
    elapsed = toc(timer);
    fprintf("Backtesting '%s' - Finished in %.2f s.\n", backtestCfg.Name, elapsed);
end









