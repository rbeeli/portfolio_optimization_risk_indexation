function funcs = backtest()
    funcs.backtest = @do_backtest;
    funcs.strategies.('MinVariance') = @MinVariance;
    funcs.strategies.('MaxReturns') = @MaxReturns;
    funcs.strategies.('EqualWeighted') = @EqualWeighted;
    funcs.strategies.('MaxSharpeRatio') = @MaxSharpeRatio;
    funcs.strategies.('EqualRiskContribution') = @EqualRiskContribution;
end


function [weights, returns, securities] = do_backtest(strategy_func, simpleRets, estimationPeriod, rebalancingInterval)
    nReturns = size(simpleRets, 1);
    
    weights = simpleRets;
    weights{:, :} = 0;
    
    returns = timetable(simpleRets.Date, NaN(nReturns, 1));
    returns.Properties.DimensionNames{1} = 'Date';
    returns.Properties.VariableNames = {'Return'};
    
    securities = cell(1, nReturns);
    
    for idx=estimationPeriod:nReturns
        if mod(idx - estimationPeriod, rebalancingInterval) == 0
            % estimate model
            
            % extract data for estimation period
            estimationData = simpleRets{(idx - estimationPeriod + 1):idx, :};

            % only consider assets which have no NaN data
            securities{idx} = find(sum(isnan(estimationData), 1) == 0);
            estimationData = estimationData(:, securities{idx});
            
            weights{idx, securities{idx}} = strategy_func(estimationData);
        else
            % no estimation, use previous weights and securities
            securities{idx} = securities{idx - 1};
            weights{idx, :} = weights{idx - 1, :};
        end
        
        % previous' period weights for current returns
        returns{idx, 1} = nansum(weights{idx - 1, :} .* simpleRets{idx, :});
    end
end


function weights = MaxReturns(period_returns)
    libopt = optimizer();
    
    % maximum return optimization
    expectedRets = expected_returns(period_returns);
    allowShorts = false;
    
    weights = libopt.MaxReturn(expectedRets, allowShorts);
    weights = weights';
end


function weights = MinVariance(period_returns)
    libopt = optimizer();
    
    % minimum variance optimization
    expectedRets = expected_returns(period_returns);
    covMatrix = covariance_matrix(period_returns);
    allowShorts = false;

    weights = libopt.MinVariance(expectedRets, covMatrix, allowShorts);
    weights = weights';
end


function weights = EqualWeighted(period_returns)
    % 1/N weights (equal weighting)
    weight = 1/size(period_returns, 2);
    weights = repelem(weight, size(period_returns, 2));
end


function weights = MaxSharpeRatio(period_returns)
    libopt = optimizer();
    
    % maximum return optimization
    expectedRets = expected_returns(period_returns);
    covMatrix = covariance_matrix(period_returns);
    
    weights = libopt.MaxSharpeRatio(expectedRets, covMatrix);
    weights = weights';
end


function weights = EqualRiskContribution(period_returns)
    libopt = optimizer();
    
    % maximum return optimization
    expectedRets = expected_returns(period_returns);
    covMatrix = covariance_matrix(period_returns);
    
    weights = libopt.EqualRiskContribution(expectedRets, covMatrix);
    weights = weights';
end





function returns = expected_returns(period_returns)
%     % simple mean
%     returns = mean(period_returns)';
    
    % EMA
    avg = movavg(period_returns, 'exponential', size(period_returns, 1));
    returns = avg(end, :)';
end


function sigma = covariance_matrix(period_returns)
%     % sample covariance
%     sigma = cov(period_returns);
    
    % Shrinkage (OAS)
    libshrinkage = shrinkage();
    sigma = libshrinkage.oas(cov(period_returns));
end
