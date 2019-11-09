function [returns, cumReturns] = read_lecture_dataset()
    % data file
    path = 'data/Seminar APT 2019 - Returns V2.xlsx';

    % read as timetable
    returns = readtable(path, 'ReadVariableNames', true, 'PreserveVariableNames', true);
    returns = removevars(returns, {'ILS (desmoothed)', 'Liability Proxy 1-3 years', 'Liability Proxy 3-5 years', 'Liability Proxy 5-7 years', 'Liability Proxy 10+ years'});

    returns.Datum = datetime(returns.Datum, 'InputFormat', 'dd.MM.yyyy');
    returns = table2timetable(returns);

    % cumulative returns column-wise
    % ignores NaN values
    cumReturns = returns(:, :);
    for col = 2:size(returns, 1)
        returns = cumReturns{:, col};
        [a, b] = find(isnan(returns));
        cumReturns{:, col} = cumprod(1 + returns{:, col});
    end
end
