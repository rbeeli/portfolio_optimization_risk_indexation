% This library deals with the estimation of expected returns.
% Two methods are provided currently:
%  1. Historical sample mean estimate
%  2. Historical exponential moving average (EMA) estimate

function funcs = libreturns()
    funcs.arithmeticMean = @arithmeticMean;
    funcs.expMovingAverage = @expMovingAverage;
end


function expectedRets = arithmeticMean(returns)
    % simple mean
    expectedRets = mean(returns)';
end


function expectedRets = expMovingAverage(returns)
    if size(returns, 1) < 3
        % fallback to SMA in case less than 3 rows available
        expectedRets = mean(returns)';
        return
    end

    % EMA
    avg = movavg(returns, 'exponential', size(returns, 1));
    expectedRets = avg(end, :)';
end
