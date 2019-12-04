classdef Constraints
    % Defines weight constraints for portfolio constituents,
    % used by the portfolio optimizer.
    
    properties
        % Constituent weights lower bounds.
        LowerBounds
        
        % Constituent weights upper bounds.
        UpperBounds
    end
    
    methods
        function constraints = Constraints(lowerBounds, upperBounds)
            constraints.LowerBounds = lowerBounds;
            constraints.UpperBounds = upperBounds;
        end
    end
end
