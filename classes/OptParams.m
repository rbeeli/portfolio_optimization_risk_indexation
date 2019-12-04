classdef OptParams
    % This object holds information as input parameters
    % for the optimizer methods.
    
    properties
        % Number of assets
        N
        
        % Expected returns
        ExpRets
        
        % Covariance matrix
        CovMat
        
        % Function returning object "Constraints"
        ConstraintsFunc
        
        % List of securities names used for this
        % optimization pass (1 x N cell array).
        Securities
    end
    
    methods
        function opts = OptParams(securities, expRets, covMat, constraintsFunc)
            opts.N = size(securities, 2);
            opts.Securities = securities;
            opts.ExpRets = expRets;
            opts.CovMat = covMat;
            opts.ConstraintsFunc = constraintsFunc;
        end
    end
end
