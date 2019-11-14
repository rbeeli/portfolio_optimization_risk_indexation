function funcs = covarianceEstimation()
    funcs.sampleCov = @sampleCov;
    funcs.sampleCovShrinkageOAS = @sampleCovShrinkageOAS;
end


function covMatrix = sampleCov(returns)
    % sample covariance
    covMatrix = cov(returns);
end


function covMatrix = sampleCovShrinkageOAS(returns)
    % shrinkage (OAS)
    libshrinkage = shrinkage();
    sigma = cov(returns);
    covMatrix = libshrinkage.oas(sigma);
end
