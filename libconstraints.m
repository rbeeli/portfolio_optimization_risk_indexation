% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

function consts = libconstraints()
    consts.defaultConstraints = @defaultConstraints;
    consts.equalMaxWeight = @equalMaxWeight;
    consts.imposeSAAonAssetClasses = @imposeSAAonAssetClasses;
end


function constraints = defaultConstraints(optParams)
    constraints = Constraints();
    
    % limit weight from 0% to 100% per asset
    constraints.LowerBounds = zeros(optParams.N, 1);
    constraints.UpperBounds = ones(optParams.N, 1);
    
    % sum to 100%
    constraints.Aeq = ones(1, optParams.N);
    constraints.beq = 1;
end

function constraints = equalMaxWeight(optParams, maxWeight)
    constraints = Constraints();
    
    % limit weight from 0% to maxWeight per asset
    constraints.LowerBounds = zeros(optParams.N, 1);
    constraints.UpperBounds = maxWeight * ones(optParams.N, 1);
    
    % sum to 100%
    constraints.Aeq = ones(1, optParams.N);
    constraints.beq = 1;
end


function constraints = imposeSAAonAssetClasses(optParams, SAA, maxWeight)
    constraints = Constraints();
    
    % limit weight from 0% to 100% per asset
    constraints.LowerBounds = zeros(optParams.N, 1);
    constraints.UpperBounds = maxWeight * ones(optParams.N, 1);
    
    % sum to 100%
    constraints.Aeq = ones(1, optParams.N);
    constraints.beq = 1;
    
    % filter by securities
    SAA = SAA(ismember(SAA.Asset_Type, optParams.Securities), :);
    
    % asset class targets
    targets = table(SAA.Asset_Class, SAA.Target_Asset_Class, SAA.Lower_Bound_Asset_Class, SAA.Upper_Bound_Asset_Class, 'VariableNames', {'AssetClass', 'Target', 'LowerBound', 'UpperBound'});
    targets = unique(targets, 'rows');
    nTargets = size(targets, 1);
    scaling = 1 / nansum(targets.Target);
    targets.Target = scaling * targets.Target; % sum to 1
    targets.UpperBound = scaling * targets.UpperBound;
    targets.LowerBound = scaling * targets.LowerBound;
    
    % first upper bounds for asset classes
    constraints.b(1:nTargets, 1) = targets.UpperBound;
    
%     % then lower bounds for asset classes
%     constraints.b((nTargets + 1):(2 * nTargets), 1) = -targets.LowerBound;
    
    for i=1:optParams.N
        security = optParams.Securities{i};
        
        % find security in SAA table
        SAArow = SAA(SAA.Asset_Type == security, :);
        assert(size(SAArow, 1) == 1, sprintf("Security `%s` not found in SAA.", security));
        
        % set 1 in constraints matrix
        assetClassIndex = find(strcmp(cellstr(targets.AssetClass), char(SAArow.Asset_Class)) == 1);
        assert(~isempty(assetClassIndex), sprintf('Asset Class "%s" not found in SAA.', SAArow.Asset_Class));
        
        % upper bounds
        constraints.A(assetClassIndex, i) = 1;
        
%         % lower bounds
%         constraints.A(nTargets + assetClassIndex, i) = -1;
    end
end






