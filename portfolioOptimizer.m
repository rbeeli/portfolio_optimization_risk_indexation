function funcs = portfolioOptimizer()
    funcs.EqualWeights = @EqualWeights;
    funcs.MinVariance = @MinVariance;
    funcs.MaxSharpeRatio = @MaxSharpeRatio;
%     funcs.MaxReturn = @MaxReturn;
    funcs.EqualRiskContribution = @EqualRiskContribution;
end


function weights = EqualWeights(expectedRets, covMatrix)
    nAssets = size(covMatrix, 1);
    weight = 1/nAssets;
    weights = repelem(weight, nAssets)';
end


function weights = MinVariance(expectedRets, covMatrix)
    nAssets = size(covMatrix, 1);
    V0 = zeros(1, nAssets);
    V1 = ones(1, nAssets);

    % set constraints
    UB = ones(nAssets,1);
    LB = zeros(nAssets,1); % no shortselling
    
    % define inequality constraints
    A1 = zeros(1, nAssets); 
    A2 = zeros(1, nAssets);
    A = [A1; A2];
    b = [1; 1];
    
    % find minimum variance weigths
    options = optimset('Algorithm','interior-point-convex',...
                       'Display','off');
    minVarWts = quadprog(covMatrix, V0, A, b, V1, 1, LB, UB, [], options);
    weights = minVarWts;
end


% function weights = MaxReturn(expectedRets)
%     nAssets = size(expectedRets, 2);
%     V1 = ones(1, nAssets);
% 
%     % set constraints
%     UB = ones(nAssets, 1);
%     LB = zeros(nAssets, 1); % no shortselling
%     
%     % define inequality constraints
%     A1 = zeros(1, nAssets); 
%     A2 = zeros(1, nAssets);
%     A = [A1; A2];
%     b = [1; 1];
%     
%     % find maximum return weights
%     weights = linprog(-expectedRets, A, b, V1, 1, LB, UB);
% end


function weights = MaxSharpeRatio(expectedRets, covMatrix)
    % http://people.stat.sc.edu/sshen/events/backtesting/reference/maximizing%20the%20sharpe%20ratio.pdf
    
    nAssets = size(covMatrix, 1);
    p = Portfolio('AssetMean',expectedRets, ...
                  'AssetCovar',covMatrix, ...
                  'UpperBound',0.4);
    
    % constraints
    p = setDefaultConstraints(p);
    ub = 1.0 * repelem(1, nAssets)';
    lb = 0.0 * repelem(1, nAssets)';
    p = setBounds(p, lb, ub);

    p = setSolver(p,'quadprog', ...
                    'Algorithm','interior-point-convex', ...
                    'Display','off', ...
                    'ConstraintTolerance',1.0e-8, ...
                    'OptimalityTolerance',1.0e-8, ...
                    'StepTolerance',1.0e-8, ...
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


function weights = EqualRiskContribution(expectedRets, covMatrix)
    nAssets = size(covMatrix, 1);
    weight = 1/nAssets;
    weights = repelem(weight, nAssets)';
    
    
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
%     minVarWts = quadprog(covMatrix, V0, A, b, V1, 1, LB);
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



