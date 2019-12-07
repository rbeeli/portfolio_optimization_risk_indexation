% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------
%
% This library deals with the estimation of expected returns.
% Two methods are provided currently:
%  1. Historical sample mean estimate
%  2. Historical exponentially smoothed average.

function funcs = libreturns()
    funcs.simpleMean = @simpleMean;
    funcs.exponentialSmoothing = @exponentialSmoothing;
end


function expectedRets = simpleMean(returns)
    % simple mean
    expectedRets = mean(returns)';
end


function expectedRets = exponentialSmoothing(returns)
    if size(returns, 1) < 3
        % fallback to SMA in case less than 3 rows available
        expectedRets = mean(returns)';
        return
    end

    % EMA
    avg = movavg(returns, 'exponential', size(returns, 1));
    expectedRets = avg(end, :)';
end
