classdef BacktestResult
    % Stores information about the results of a backtest.
    
    properties
        % BacktestConfig object used for backtest.
        Config
        
        % Strategy weights  time series as computed by optimizer.
        StrategyWgts
        
        % Portfolio weights time series based on strategy weights,
        % but including price change effects.
        PortfolioWgts
        
        % Portfolio returns time series.
        PortfolioRets
        
        % Portfolio constituents risk contribution time series.
        RiskCtb
    end
    
    methods
        function obj = BacktestResult(backtestCfg)
            obj.Config = backtestCfg;
        end
    end
end
