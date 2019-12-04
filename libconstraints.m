function consts = libconstraints()
    consts.equalMaxWeight = @equalMaxWeight;
    consts.imposeSAAPositionLevel = @imposeSAAPositionLevel;
end


function constraints = equalMaxWeight(optParams)
    % Constraints
    lowerBounds = zeros(optParams.N, 1);
    upperBounds = 0.3 * ones(optParams.N, 1);
    constraints = Constraints(lowerBounds, upperBounds);
end


function constraints = imposeSAAPositionLevel(optParams, SAA)
    % Constraints
    lowerBounds = zeros(optParams.N, 1);
    upperBounds = zeros(optParams.N, 1);
    targets = zeros(optParams.N, 1);
    
    for i=1:optParams.N
        security = optParams.Securities{i};
        SAArow = SAA(SAA.Asset_Type == security, :);
        
        assert(size(SAArow, 1) == 1, sprintf("Security `%s` not found in SAA.", security));
        
        lowerBounds(i, 1) = SAArow.Lower_Bound;
        upperBounds(i, 1) = SAArow.Upper_Bound;
        targets(i, 1) = SAArow.Target;
    end
    
    % scale weights to sum up to 1
    scalingFactor = 1 / sum(targets);
    targets = targets * scalingFactor;
    lowerBounds = lowerBounds * scalingFactor;
    upperBounds = upperBounds * scalingFactor;
    
    constraints = Constraints(lowerBounds, upperBounds);
end


function constraints = imposeSAAAssetClassLevel(optParams, SAA)
    % Constraints
    lowerBounds = zeros(optParams.N, 1);
    upperBounds = zeros(optParams.N, 1);
    targets = zeros(optParams.N, 1);
    
    for i=1:optParams.N
        security = optParams.Securities{i};
        SAArow = SAA(SAA.Asset_Type == security, :);
        
        assert(size(SAArow, 1) == 1, sprintf("Security `%s` not found in SAA.", security));
        
        lowerBounds(i, 1) = SAArow.Lower_Bound;
        upperBounds(i, 1) = SAArow.Upper_Bound;
        targets(i, 1) = SAArow.Target;
    end
    
    % scale weights to sum up to 1
    scalingFactor = 1 / sum(targets);
    targets = targets * scalingFactor;
    lowerBounds = lowerBounds * scalingFactor;
    upperBounds = upperBounds * scalingFactor;
    
    constraints = Constraints(lowerBounds, upperBounds);
end