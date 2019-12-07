% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

function funcs = liboptimizer()
    funcs.EqualWeights = @EqualWeights;
    funcs.MinVariance = @MinVariance;
    funcs.MaxSharpeRatio = @MaxSharpeRatio;
    funcs.EqualRiskContribution = @EqualRiskContribution;
end


function weights = EqualWeights(optParams)
    weights = repelem(1/optParams.N, optParams.N)';
end


function weights = MinVariance(optParams)
    f = zeros(1, optParams.N);
    
    % compute constraints
    constraints = optParams.ConstraintsFunc(optParams);
    
    % lower/upper bounds
    lb = constraints.LowerBounds;
    ub = constraints.UpperBounds;
    
    % equality constraints
    Aeq = constraints.Aeq;
    beq = constraints.beq;
    
    % inequality constraints
    A = constraints.A;
    b = constraints.b;
    
    % scale covariance matrix by large factor for
    % increased optimization accuracy
    H = optParams.CovMat * 10^10;
    
    % find minimum variance weigths
    opts = optimset('Algorithm','interior-point-convex', 'Display','off');
    weights = quadprog(H, f, A, b, Aeq, beq, lb, ub, [], opts);
end


function weights = MaxSharpeRatio(optParams)
    % http://people.stat.sc.edu/sshen/events/backtesting/reference/maximizing%20the%20sharpe%20ratio.pdf
    
    p = Portfolio('AssetMean',optParams.ExpRets, ...
                  'AssetCovar',optParams.CovMat);

    % initial weights (equal weighted)
    p = setInitPort(p, 1/optParams.N, optParams.N);
    
    % compute constraints
    constraints = optParams.ConstraintsFunc(optParams);
    
    % lower/upper bounds
    p = setBounds(p, constraints.LowerBounds, constraints.UpperBounds);
    
    % equality constraints
    p = setEquality(p, constraints.Aeq, constraints.beq);
    
    % inequality constraints
    p = setInequality(p, constraints.A, constraints.b);
    
    try
        weights = estimateMaxSharpeRatio(p); 
    catch ME
        if (strcmp(ME.identifier, 'finance:Portfolio:estimateMaxSharpeRatio:CannotObtainMaximum'))
            disp('Max. Sharpe Ratio Optimization failed:');
            disp(ME.message);
            disp('Using equal weights');
            
            weights = repelem(1/optParams.N, optParams.N)';
        else
            rethrow(ME)
        end
    end 
    
%     nAssets = size(expectedRets, 2);
%     V0 = zeros(1, nAssets);
%     V1 = ones(1, nAssets);
% 
%     % set constraints
%     UB = ones(nAssets,1);
%     LB = zeros(nAssets,1);
%     
%     if allowShortselling
%         LB = -ones(nAssets,1);
%     end
%     
%     % define inequality constraints
%     A1 = zeros(1, nAssets); 
%     A2 = zeros(1, nAssets);
%     A = [A1; A2];
%     b = [1; 1];
%     
%     % find minimum variance return
%     minVarWts = quadprog(CovMat, V0, A, b, V1, 1, LB);
%     minVarRet = minVarWts'*ExpRet;
%     
%     % find maximum return
%     maxRetWts = quadprog([], -ExpRet, A, b, V1, 1, LB);
%     maxRet = maxRetWts'*ExpRet;
%     
%     % calculate frontier portfolios
%     numPort = 5;
%     targetRet = linspace(minVarRet, maxRet, numPort);
%     
%     frontWeights = zeros(nAssets, numPort);
%     frontWeights(:, 1) = minVarWts;
%     
%     Aeq = [V1; ExpRet'];
% 
%     for i = 2:numPort
%         beq = [1; targetRet(i)];
%         frontWeights(:, i) = quadprog(CovMat, V0, A, b, Aeq, beq, LB, UB);
%     end
end


function weights = EqualRiskContribution(optParams)
    % compute constraints
    constraints = optParams.ConstraintsFunc(optParams);
    
    % lower/upper bounds
    lb = constraints.LowerBounds;
    ub = constraints.UpperBounds;
    
    % equality constraints
    Aeq = constraints.Aeq;
    beq = constraints.beq;
    
    % inequality constraints
    A = constraints.A;
    b = constraints.b;
    
    % initial weights (equal weighted)
    x0 = 1/optParams.N * ones(optParams.N, 1);
    
    % scale covariance matrix by large factor for increased optimization accuracy
    Sigma = optParams.CovMat * 10^14;
    
    % Sequential Quadratic Programming (SQP) algorithm
    fun = @(W) var(W.*(Sigma*W));
    opts = optimset('Display', 'off');
    weights = fmincon(fun, x0, A, b, Aeq, beq, lb, ub, [], opts);
end







