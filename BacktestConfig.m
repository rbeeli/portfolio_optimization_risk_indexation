classdef BacktestConfig
    % This class is used to define how a backtest is executed.
    % The user can set properties in order to specify:
    %  - Expected returns estimation function
    %  - Covariance estimation function
    %  - Portfolio optimization algorithm
    %  - Estimation window
    %  - Estimation intervals
    %  - Rebalancing intervals (TODO)
    %  - Returns time series (timetable)
    %  - List of security names
    
    properties
        Name
        ExpectedRetsFunc
        ExpectedRetsDataFunc
        CovFunc
        CovDataFunc
        PortOptimizerFunc
        EstimationInterval {mustBeNumeric}
        RebalancingInterval {mustBeNumeric}
        Returns
        Securities
        StartIndex {mustBeNumeric}
    end
    
    methods
        function obj = BacktestConfig(name)
            obj.Name = name;
            obj.StartIndex = 1;
        end
    end
end
