function funcs = liboptimizer()
    funcs.EqualWeights = @EqualWeights;
    funcs.MinVariance = @MinVariance;
    funcs.MaxSharpeRatio = @MaxSharpeRatio;
    funcs.EqualRiskContribution = @EqualRiskContribution;
end


function weights = EqualWeights(params)
    weight = 1/params.N;
    weights = repelem(weight, params.N)';
end


function weights = MinVariance(params)
    V0 = zeros(1, params.N);
    V1 = ones(1, params.N);
    
    % define inequality constraints
    A1 = zeros(1, params.N); 
    A2 = zeros(1, params.N);
    A = [A1; A2];
    b = [1; 1];
    
    % scale covariance matrix by large factor for
    % increased optimization accuracy
    Sigma = params.CovMat * 10^10;
    
    % find minimum variance weigths
    options = optimset('Algorithm','interior-point-convex', ...
                       'Display','off');
    weights = quadprog(Sigma, V0, A, b, V1, 1, params.LowerBounds, params.UpperBounds, [], options);
end


function weights = MaxSharpeRatio(params)
    % http://people.stat.sc.edu/sshen/events/backtesting/reference/maximizing%20the%20sharpe%20ratio.pdf
    
    p = Portfolio('AssetMean',params.ExpRets, ...
                  'AssetCovar',params.CovMat, ...
                  'LowerBound',params.LowerBounds, ...
                  'UpperBound',params.UpperBounds);
    
    % constraints
    p = setDefaultConstraints(p);
    p = setBounds(p, params.LowerBounds, params.UpperBounds);

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


function weights = EqualRiskContribution(params)
    nAssets = size(params.CovMat, 1);
    
    % initial weights (equal weighted)
    w0 = 1/nAssets * ones(params.N, 1);
    A = ones(1, params.N);
    b = 1;
    
    % scale covariance matrix by large factor for
    % increased optimization accuracy
    Sigma = params.CovMat * 10^14;
    
    % Sequential Quadratic Programming (SQP) algorithm
    f = @(W) var(W.*(Sigma*W));
    opts = optimset('Display', 'off');
    weights = fmincon(f, w0, [], [], A, b, params.LowerBounds, params.UpperBounds, [], opts);
end







