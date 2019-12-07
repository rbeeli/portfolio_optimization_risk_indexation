% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------
%
% This library deals with the estimation of covariance matrices.
% Two methods are provided currently:
%  1. Historical sample covariance estimate
%  2. Historical OAS shrinkage estimate

function funcs = libcovariance()
    funcs.sampleCov = @sampleCov;
    funcs.sampleCovShrinkageOAS = @sampleCovShrinkageOAS;
end


function covMatrix = sampleCov(returns)
    % sample covariance
    covMatrix = cov(returns);
end


function covMatrix = sampleCovShrinkageOAS(returns)
    % shrinkage (OAS)
    covMatrix = libshrinkage().oas(returns);
end
