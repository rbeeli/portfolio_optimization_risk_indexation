function opt = optimizer()
    opt.MinVariance = @MinVariance;
    opt.MaxSharpeRatio = @MaxSharpeRatio;
    opt.MaxReturn = @MaxReturn;
    opt.EqualRiskContribution = @EqualRiskContribution;
end


function weights = MinVariance(ExpRet, CovMat, allowShortselling)
    numAssets = length(ExpRet);
    V0 = zeros(1, numAssets);
    V1 = ones(1, numAssets);

    % set constraints
    UB = 0.3 * ones(numAssets,1);
    LB = zeros(numAssets,1);
    
    if allowShortselling
        LB = -ones(numAssets,1);
    end
    
    % define inequality constraints
    A1 = zeros(1, numAssets); 
    A2 = zeros(1, numAssets);
    A = [A1; A2];
    b = [1; 1];
    
    % find minimum variance weigths
    minVarWts = quadprog(CovMat, V0, A, b, V1, 1, LB, UB);
    weights = minVarWts;
end


function weights = MaxReturn(ExpRet, allowShortselling)
    numAssets = length(ExpRet);
    V1 = ones(1, numAssets);

    % set constraints
    UB = ones(numAssets,1);
    LB = zeros(numAssets,1);
    
    if allowShortselling
        LB = -ones(numAssets,1);
    end
    
    % define inequality constraints
    A1 = zeros(1, numAssets); 
    A2 = zeros(1, numAssets);
    A = [A1; A2];
    b = [1; 1];
    
    % find maximum return weights
    weights = linprog(-ExpRet, A, b, V1, 1, LB, UB);
end


function weights = MaxSharpeRatio(ExpRet, CovMat)
    % http://people.stat.sc.edu/sshen/events/backtesting/reference/maximizing%20the%20sharpe%20ratio.pdf
    
    p = Portfolio('AssetMean',ExpRet, 'AssetCovar',CovMat, 'UpperBound',0.4);
    
    % constraints
    p = setDefaultConstraints(p);
    lb = repelem(0, size(CovMat, 1))';
    ub = repelem(0.3, size(CovMat, 1))';
    p = setBounds(p, lb, ub);

    p = setSolver(p,'quadprog',...
                    'Display','off',...
                    'ConstraintTolerance',1.0e-8,...
                    'OptimalityTolerance',1.0e-8,...
                    'StepTolerance',1.0e-8,...
                    'MaxIterations',10000);
    weights = estimateMaxSharpeRatio(p); 
    
%     numAssets = length(ExpRet);
%     V0 = zeros(1, numAssets);
%     V1 = ones(1, numAssets);
% 
%     % set constraints
%     UB = ones(numAssets,1);
%     LB = zeros(numAssets,1);
%     
%     if allowShortselling
%         LB = -ones(numAssets,1);
%     end
%     
%     % define inequality constraints
%     A1 = zeros(1, numAssets); 
%     A2 = zeros(1, numAssets);
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
%     frontWeights = zeros(numAssets, numPort);
%     frontWeights(:, 1) = minVarWts;
%     
%     Aeq = [V1; ExpRet'];
% 
%     for i = 2:numPort
%         beq = [1; targetRet(i)];
%         frontWeights(:, i) = quadprog(CovMat, V0, A, b, Aeq, beq, LB, UB);
%     end
end


function weights = EqualRiskContribution(ExpRet, CovMat)
    weight = 1/size(CovMat, 1);
    weights = repelem(weight, size(CovMat, 1))';
    
    
%     numAssets = length(ExpRet);
%     V0 = zeros(1, numAssets);
%     V1 = ones(1, numAssets);
% 
%     % set constraints
%     UB = ones(numAssets,1);
%     LB = zeros(numAssets,1);
%     
%     if allowShortselling
%         LB = -ones(numAssets,1);
%     end
%     
%     % define inequality constraints
%     A1 = zeros(1, numAssets); 
%     A2 = zeros(1, numAssets);
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
%     frontWeights = zeros(numAssets, numPort);
%     frontWeights(:, 1) = minVarWts;
%     
%     Aeq = [V1; ExpRet'];
% 
%     for i = 2:numPort
%         beq = [1; targetRet(i)];
%         frontWeights(:, i) = quadprog(CovMat, V0, A, b, Aeq, beq, LB, UB);
%     end
end



