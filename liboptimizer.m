function funcs = liboptimizer()
    funcs.EqualWeights = @EqualWeights;
    funcs.MinVariance = @MinVariance;
    funcs.MinVarianceConstrained = @MinVarianceConstrained;
    funcs.MaxSharpeRatio = @MaxSharpeRatio;
    funcs.EqualRiskContribution = @EqualRiskContribution;
end


function weights = EqualWeights(optParams)
    weight = 1/optParams.N;
    weights = repelem(weight, optParams.N)';
end


function weights = MinVariance(optParams)
    f = zeros(1, optParams.N);
    Aeq = ones(1, optParams.N);
    beq = 1;
    lb = zeros(optParams.N, 1);
    ub = ones(optParams.N, 1);
    
    % define inequality constraints
    A = [zeros(1, optParams.N); zeros(1, optParams.N)];
    b = [1; 1];
    
    % scale covariance matrix by large factor for
    % increased optimization accuracy
    H = optParams.CovMat * 10^10;
    
    % find minimum variance weigths
    opts = optimset('Algorithm','interior-point-convex', 'Display','off');
    weights = quadprog(H, f, A, b, Aeq, beq, lb, ub, [], opts);
end


function weights = MinVarianceConstrained(optParams)
    f = zeros(1, optParams.N);
    Aeq = ones(1, optParams.N);
    beq = 1;
    
    % compute weight constraints
    constraints = optParams.ConstraintsFunc(optParams);
    lb = constraints.LowerBounds;
    ub = constraints.UpperBounds;
    
    % define inequality constraints
    A = [zeros(1, optParams.N); zeros(1, optParams.N)];
    b = [1; 1];
    
    % scale covariance matrix by large factor for
    % increased optimization accuracy
    H = optParams.CovMat * 10^10;
    
    % find minimum variance weigths
    opts = optimset('Algorithm','interior-point-convex', 'Display','off');
    weights = quadprog(H, f, A, b, Aeq, beq, lb, ub, [], opts);
end


function weights = MaxSharpeRatio(optParams)
    % http://people.stat.sc.edu/sshen/events/backtesting/reference/maximizing%20the%20sharpe%20ratio.pdf
    
    lb = zeros(optParams.N, 1);
    ub = ones(optParams.N, 1);
    
    p = Portfolio('AssetMean',optParams.ExpRets, ...
                  'AssetCovar',optParams.CovMat);
    
    % constraints
    p = setDefaultConstraints(p);
    p = setBounds(p, lb, ub);

    p = setSolver(p,'quadprog', ...
                    'Algorithm','interior-point-convex', ...
                    'Display','off', ...
                    'ConstraintTolerance',1.0e-10, ...
                    'OptimalityTolerance',1.0e-10, ...
                    'StepTolerance',1.0e-10, ...
                    'MaxIterations',10000);
    weights = estimateMaxSharpeRatio(p); 
    
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
    nAssets = size(optParams.CovMat, 1);
    
    
    % initial weights (equal weighted)
    x0 = 1/nAssets * ones(optParams.N, 1);
    Aeq = ones(1, optParams.N);
    beq = 1;
    lb = zeros(optParams.N, 1);
    ub = ones(optParams.N, 1);
    
    % scale covariance matrix by large factor for increased optimization accuracy
    Sigma = optParams.CovMat * 10^14;
    
    % Sequential Quadratic Programming (SQP) algorithm
    fun = @(W) var(W.*(Sigma*W));
    opts = optimset('Display', 'off');
    weights = fmincon(fun, x0, [], [], Aeq, beq, lb, ub, [], opts);
end







