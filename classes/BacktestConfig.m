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
        Label
        ExpectedRetsFunc
        ExpectedRetsDataFunc
        CovFunc
        CovDataFunc
        PortOptimizerFunc
        OptimizationInterval {mustBeNumeric}
        RebalancingInterval {mustBeNumeric}
        Returns
        Securities
        StartIndex {mustBeNumeric}
        ConstraintsFunc
    end
    
    methods
        function obj = BacktestConfig(name, label)
            obj.Name = name;
            obj.Label = label;
            obj.StartIndex = 1;
        end
    end
end
