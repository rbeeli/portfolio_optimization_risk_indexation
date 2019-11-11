function funcs = data()
    funcs.read_lecture_dataset = @read_lecture_dataset;
    funcs.cumulative_returns = @cumulative_returns;
    funcs.summary_stats = @summary_stats;
    funcs.read_sp500_dataset = @read_sp500_dataset;
    funcs.sharpe_ratio = @sharpe_ratio;
end


function [indexRets, stockRets, frequency] = read_sp500_dataset()
    % read Excel
    indexRets = readtable('data/SP500/sp500_index_monthly.csv', 'ReadVariableNames',true, 'PreserveVariableNames',true);
    stockRets = readtable('data/SP500/sp500_stock_returns.csv', 'ReadVariableNames',true, 'PreserveVariableNames',true);
    
    % rename columns
    indexRets.Properties.VariableNames = {'Date' 'Value-Weighted' 'Equal-Weighted'};
    stockRets.Properties.VariableNames(1) = {'Date'};

    % parse date
    indexRets.Date = datetime(indexRets.Date, 'InputFormat', 'yyyy-MM-dd');
    stockRets.Date = datetime(stockRets.Date, 'InputFormat', 'yyyy-MM-dd');
    
    % convert to timetable
    indexRets = table2timetable(indexRets);
    stockRets = table2timetable(stockRets);
    
    % monthly data
    frequency = 12;
end


function [returns, frequency] = read_lecture_dataset()
    % read Excel
    returns = readtable('data/Seminar APT 2019 - Returns V2.xlsx', 'ReadVariableNames',true, 'PreserveVariableNames',true);
    returns = removevars(returns, {
        'ILS (desmoothed)',...
        'Liability Proxy 1-3 years',...
        'Liability Proxy 3-5 years',...
        'Liability Proxy 5-7 years',...
        'Liability Proxy 10+ years'
    });
    returns.Properties.VariableNames(1) = {'Date'};

    % parse date
    returns.Date = datetime(returns.Date, 'InputFormat', 'dd.MM.yyyy');
    
    % convert to timetable
    returns = table2timetable(returns);
    
    % monthly data
    frequency = 12;
end


function cumReturns = cumulative_returns(simpleReturns)
    % create copy of returns table with NaNs
    cumReturns = simpleReturns;
    cumReturns{:, :} = nan;
    
    % compute column-wise compound returns.
    % ignores NaN values.
    for col = 1:size(simpleReturns, 2)
        returns = simpleReturns{:, col};
        
        % ignore NaN rows for returns calculation
        data_indices = find(~isnan(returns));
        cumReturns{data_indices, col} = cumprod(1 + returns(data_indices));
    end
end


function stats = summary_stats(simpleRets, cumRets, frequency)
    nAssets = size(simpleRets, 2);
    periods = sum(~isnan(simpleRets{:, :}));
    years = periods'/frequency;
    
    statReturns = NaN(nAssets, 1);
    statVol = NaN(nAssets, 1);
    statSkew = NaN(nAssets, 1);
    statKurt = NaN(nAssets, 1);
    
    for col = 1:nAssets
        dataIndices = find(~isnan(cumRets{:, col}));
        assetSimpleRets = simpleRets{dataIndices, col};
        assetCumRets = cumRets{dataIndices, col};
        
        if size(dataIndices, 1) > 0
            statReturns(col) = 100 * (assetCumRets(end) ^ (frequency/periods(col)) - 1);
            statVol(col) = 100 * sqrt(frequency) * std(assetSimpleRets);
            statSkew(col) = skewness(assetSimpleRets);
            statKurt(col) = kurtosis(assetSimpleRets);
        end
    end
    
    colNames = [{'Asset Class'} {'Years'} {'Return p.a.'} {'Volatility p.a.'} {'Skewness'} {'Kurtosis'}];
    rowNames = simpleRets.Properties.VariableNames';
    tableData = string([round(years) round([statReturns statVol statSkew statKurt]*100)/100]);
    stats = [colNames; rowNames tableData];
end


function SR = sharpe_ratio(simpleRets, frequency)
    nAssets = size(simpleRets, 2);
    SR = NaN(nAssets, 1);
    
    for col = 1:nAssets
        dataIndices = find(~isnan(simpleRets{:, col}));
        assetSimpleRets = simpleRets{dataIndices, col};
        
        if size(dataIndices, 1) > 0
            SR(col) = sqrt(frequency) * mean(assetSimpleRets) / std(assetSimpleRets);
        end
    end
end


