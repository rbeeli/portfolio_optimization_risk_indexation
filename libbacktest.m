function funcs = libbacktest()
    funcs.execute = @execute;
end


function result = execute(backtestCfg)
    disp(strcat("Backtesting `", backtestCfg.Name, "` ..."));
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
    
    % portfolio returns
    result.PortfolioRets = timetable(backtestCfg.Returns.Date, NaN(nReturns, 1));
    result.PortfolioRets.Properties.DimensionNames{1} = 'Date';
    result.PortfolioRets.Properties.VariableNames = {'Return'};
    
    % do backtest
    nSteps = nReturns - backtestCfg.StartIndex + 1;
    for idx=backtestCfg.StartIndex:nReturns
        stepIndex = idx - backtestCfg.StartIndex;
        
        fprintf("%s - Progress: %.2f%%\n", backtestCfg.Name, stepIndex / nSteps * 100);
        
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
            covMat = [];
            if isa(backtestCfg.CovFunc, 'function_handle')
                covMat = backtestCfg.CovFunc(covData);
            end
            
            % optimize portfolio/calculate weights
            opts = OptParams(securitiesNames, expRets, covMat, backtestCfg.ConstraintsFunc);
            
            result.PortfolioWgts{idx, securities} = backtestCfg.PortOptimizerFunc(opts)';
            result.StrategyWgts{idx, securities} = backtestCfg.PortOptimizerFunc(opts)';
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
            
            % adjust portfolio weights for previous period return and rescale to sum up to 100%
            result.PortfolioWgts{idx, :} = result.PortfolioWgts{idx - 1, :} .* (1 + backtestCfg.Returns{idx, :});
            result.PortfolioWgts{idx, :} = result.PortfolioWgts{idx, :} ./ nansum(result.PortfolioWgts{idx, :});
        end
        
        % previous' period weights for current returns
        result.PortfolioRets{idx, 1} = nansum(result.PortfolioWgts{idx - 1, :} .* backtestCfg.Returns{idx, :});
        
        % sanity checks - ensure weights sum to 1
%         assert(abs(nansum(result.PortfolioWgts{idx, :}) - 1) < 0.0001, strcat("Portfolio weights of strategy `", backtestCfg.Name, "` must sum to 1."));
%         assert(abs(nansum(result.StrategyWgts{idx, :}) - 1) < 0.0001, strcat("Strategy weights of strategy `", backtestCfg.Name, "` must sum to 1."));
    end
    
    elapsed = toc(timer);
    disp(strcat("Backtesting `", backtestCfg.Name, "` finished in ", num2str(elapsed), " s"));
end









