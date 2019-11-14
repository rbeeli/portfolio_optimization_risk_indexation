function funcs = backtest()
    funcs.execute = @execute;
end


function result = execute(backtestCfg)
    disp(strcat("Backtesting strategy: ", backtestCfg.Name));

    nReturns = size(backtestCfg.Returns, 1);
    
    % store backtest result in object
    result = BacktestResult(backtestCfg);

    % portfolio weights over time
    result.PortfolioWeights = backtestCfg.Returns;
    result.PortfolioWeights{:, :} = nan;
    
    % portfolio returns
    result.PortfolioReturns = timetable(backtestCfg.Returns.Date, NaN(nReturns, 1));
    result.PortfolioReturns.Properties.DimensionNames{1} = 'Date';
    result.PortfolioReturns.Properties.VariableNames = {'Return'};
    
    % do backtest
    for idx=backtestCfg.StartIndex:nReturns
        if mod(idx - backtestCfg.StartIndex, backtestCfg.EstimationInterval) == 0
            % estimate model
            
            % extract data for estimating returns and covariance
            expectedRetsData = backtestCfg.ExpectedRetsDataFunc(backtestCfg.Returns, idx);
            covData = backtestCfg.ExpectedRetsDataFunc(backtestCfg.Returns, idx);

            % only consider assets which have no NaN data
            securities = find((sum(isnan(expectedRetsData), 1) == 0) & (sum(isnan(covData), 1) == 0));
            expectedRetsData = expectedRetsData(:, securities);
            covData = covData(:, securities);
            
            % estimate expected returns
            expectedRets = backtestCfg.ExpectedRetsFunc(expectedRetsData);

            % estimate covariance
            covMatrix = backtestCfg.CovFunc(covData);
            
            % optimize portfolio/calculate weights
            result.PortfolioWeights{idx, securities} = backtestCfg.PortOptimizerFunc(expectedRets, covMatrix)';
        else
            % no estimation, use previous weights
            result.PortfolioWeights{idx, :} = result.PortfolioWeights{idx - 1, :};
        end
        
        % previous' period weights for current returns
        result.PortfolioReturns{idx, 1} = nansum(result.PortfolioWeights{idx - 1, :} .* backtestCfg.Returns{idx, :});
    end
end





