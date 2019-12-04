function funcs = libdata()
    funcs.readLectureDataset = @readLectureDataset;
    funcs.cumulativeReturns = @cumulativeReturns;
    funcs.summaryStats = @summaryStats;
    funcs.readSP500Dataset = @readSP500Dataset;
    funcs.sharpeRatio = @sharpeRatio;
    funcs.extractWindow = @extractWindow;
    funcs.readNASDAQ100Dataset = @readNASDAQ100Dataset;
end


function [indexRets, stockRets, frequency] = readSP500Dataset()
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


function [stockRets, frequency] = readNASDAQ100Dataset()
    % read Excel
    stockRets = readtable('data/NASDAQ-100/NASDAQ-100_stocks_monthly_wide.csv', 'ReadVariableNames',true, 'PreserveVariableNames',true);
    
    % rename columns
    stockRets.Properties.VariableNames(1) = {'Date'};

    % parse date
    stockRets.Date = datetime(stockRets.Date, 'InputFormat', 'yyyy-MM-dd');
    
    % convert to timetable
    stockRets = table2timetable(stockRets);
    
    % monthly data
    frequency = 12;
end


function [returns, frequency] = readLectureDataset()
    % read Excel
    returns = readtable('data/lecture_dataset/Seminar APT 2019 - Returns V2.xlsx', 'ReadVariableNames',true, 'PreserveVariableNames',true);
    returns.Properties.VariableNames(1) = {'Date'};
%     returns = removevars(returns, {
%         'ILS (desmoothed)',...
%         'Liability Proxy 1-3 years',...
%         'Liability Proxy 3-5 years',...
%         'Liability Proxy 5-7 years',...
%         'Liability Proxy 10+ years'
%     });

    % parse date
    returns.Date = datetime(returns.Date, 'InputFormat', 'dd.MM.yyyy');
    
    % convert to timetable
    returns = table2timetable(returns);
    
    % monthly data
    frequency = 12;
end


function cumReturns = cumulativeReturns(simpleRets)
    % create copy of returns table with NaNs
    cumReturns = simpleRets;
    cumReturns{:, :} = nan;
    
    % compute column-wise compound returns.
    % ignores NaN values.
    for col = 1:size(simpleRets, 2)
        returns = simpleRets{:, col};
        
        % ignore NaN rows for returns calculation
        dataIndices = ~isnan(returns);
        cumReturns{dataIndices, col} = cumprod(1 + returns(dataIndices));
    end
end


function stats = summaryStats(simpleRets, frequency)
    nAssets = size(simpleRets, 2);
    periods = sum(~isnan(simpleRets{:, :}));
    years = periods'/frequency;
    cumRets = cumulativeReturns(simpleRets);
    
    statReturns = NaN(nAssets, 1);
    statWorst = NaN(nAssets, 1);
    statBest = NaN(nAssets, 1);
    statVol = NaN(nAssets, 1);
    statSkew = NaN(nAssets, 1);
    statKurt = NaN(nAssets, 1);
    
    for col = 1:nAssets
        dataIndices = ~isnan(cumRets{:, col});
        assetSimpleRets = simpleRets{dataIndices, col};
        assetCumRets = cumRets{dataIndices, col};
        
        if size(assetSimpleRets, 1) > 0
            statReturns(col) = 100 * (assetCumRets(end) ^ (frequency/periods(col)) - 1);
            statVol(col) = 100 * sqrt(frequency) * std(assetSimpleRets);
            statSkew(col) = skewness(assetSimpleRets);
            statKurt(col) = kurtosis(assetSimpleRets);
            statWorst(col) = min(assetSimpleRets);
            statBest(col) = max(assetSimpleRets);
        end
    end
    
    colNames = [{'Asset Class'} {'Years'} {'Return p.a.'} {'Worst'}  {'Best'} {'Volatility p.a.'} {'Skewness'} {'Kurtosis'}];
    rowNames = simpleRets.Properties.VariableNames';
    tableData = string([round(years) round([statReturns statWorst statBest statVol statSkew statKurt]*100)/100]);
    stats = [colNames; rowNames tableData];
end


function SR = sharpeRatio(simpleRets, frequency)
    nAssets = size(simpleRets, 2);
    SR = NaN(nAssets, 1);
    
    for col = 1:nAssets
        dataIndices = ~isnan(simpleRets{:, col});
        assetSimpleRets = simpleRets{dataIndices, col};
        
        if size(assetSimpleRets, 1) > 0
            SR(col) = sqrt(frequency) * mean(assetSimpleRets) / std(assetSimpleRets);
        end
    end
end


function windowRets = extractWindow(returns, position, lookbackWindow)
    % Extracts a data window of size "lookbackWindow" up to
    % row "position", but not including it.
    %
    % Example:
    %    position=10
    %    lookbackWindow=3
    %    idxFrom=7
    %    idxTo=9
    idxFrom = max(1, position - lookbackWindow);
    idxTo = min(size(returns, 1), position - 1);
    windowRets = returns{idxFrom:idxTo, :};
end
