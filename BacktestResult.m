classdef BacktestResult
    % Stores information about the results of a simulated
    % backtest.
    
    properties
        Config
        PortfolioWeights
        PortfolioReturns
    end
    
    methods
        function obj = BacktestResult(backtestCfg)
            obj.Config = backtestCfg;
        end
    end
end
