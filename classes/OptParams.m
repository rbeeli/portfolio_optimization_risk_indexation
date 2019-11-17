classdef OptParams
    % This object holds information as input parameters for the optimizer
    % methods.
    
    properties
        % Number of assets
        N
        
        % Expected returns
        ExpRets
        
        % Covariance matrix
        CovMat
        
        % Asset weights lower bounds
        LowerBounds
        
        % Asset weights upper bounds
        UpperBounds
    end
    
    methods
        function opts = OptParams(expRets, covMat)
            opts.ExpRets = expRets;
            opts.CovMat = covMat;
            opts.N = size(covMat, 1);
            
            % set default weight bounds to [0, 1]
            opts.LowerBounds = zeros(opts.N, 1);
            opts.UpperBounds = ones(opts.N, 1);
        end
    end
end
