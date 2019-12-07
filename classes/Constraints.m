classdef Constraints
    % Defines weight constraints for portfolio constituents,
    % used by the portfolio optimizer.
    % See Matlab documentation of function "quadprog" for details.
    
    properties
        % Constituent weights lower bounds.
        LowerBounds
        
        % Constituent weights upper bounds.
        UpperBounds
        
        % Inequality constraints matrix A
        A
        
        % Inequality constraints vector b
        b
        
        % Equality constraints matrix Aeq
        Aeq
        
        % Equality constraints vector beq
        beq
    end
end
