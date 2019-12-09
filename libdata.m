% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

function funcs = libdata()
    % datasets
    funcs.readLectureDataset = @readLectureDataset;
    funcs.readLectureNoCashDataset = @readLectureNoCashDataset;
    funcs.readSP500Dataset = @readSP500Dataset;
    funcs.readNASDAQ100Dataset = @readNASDAQ100Dataset;
    funcs.readDJIA30Dataset = @readDJIA30Dataset;
    
    % Strategic Asset Allocation
    funcs.readSAA = @readSAA;
    
    % calculation functions
    funcs.cumulativeReturns = @cumulativeReturns;
    funcs.summaryStats = @summaryStats;
    funcs.sharpeRatio = @sharpeRatio;
    funcs.extractWindow = @extractWindow;
end


function SAA = readSAA()
    T = readtable('data/SAA.xlsx');
    
    T(size(T, 1), :) = []; % remove summary row
    T.Asset_Class = categorical(T.Asset_Class);
    T.Asset_Type = categorical(T.Asset_Type);
    
    assert(sum(T.Target) == 1.0, "Target weights of SAA need to sum up to 100%.");
    
    SAA = T;
end

function [name, indexRets, stockRets, frequency] = readSP500Dataset()
    % technical name of dataset
    name = 'SP500';
    
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


function [name, stockRets, frequency] = readNASDAQ100Dataset()
    % technical name of dataset
    name = 'NASDAQ100';
    
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


function [name, stockRets, frequency] = readDJIA30Dataset()
    % technical name of dataset
    name = 'DJIA30';
    
    % read Excel
    stockRets = readtable('data/DJIA30/DJIA_stocks_monthly_wide.csv', 'ReadVariableNames',true, 'PreserveVariableNames',true);
    
    % rename columns
    stockRets.Properties.VariableNames(1) = {'Date'};

    % parse date
    stockRets.Date = datetime(stockRets.Date, 'InputFormat', 'yyyy-MM-dd');
    
    % convert to timetable
    stockRets = table2timetable(stockRets);
    
    % monthly data
    frequency = 12;
end


function [name, returns, frequency] = readLectureNoCashDataset()
    [name, returns, frequency] = readLectureDataset();
    name = 'lectureNoCash';
    
    returns = removevars(returns, {
        'Cash CHF'
    });
end


function [name, returns, frequency] = readLectureDataset()
    % technical name of dataset
    name = 'lecture';
    
    % read Excel
    returns = readtable('data/lecture_dataset/Seminar APT 2019 - Returns V2.xlsx', 'ReadVariableNames',true, 'PreserveVariableNames',true);
    returns.Properties.VariableNames(1) = {'Date'};
    returns = removevars(returns, {
        'Liability Proxy 1-3 years',...
        'Liability Proxy 3-5 years',...
        'Liability Proxy 5-7 years',...
        'Liability Proxy 10+ years'
    });

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
    
    statSR = NaN(nAssets, 1);
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
            statSR(col) = sqrt(frequency) * mean(assetSimpleRets) / std(assetSimpleRets);
            statReturns(col) = 100 * (assetCumRets(end) ^ (frequency/periods(col)) - 1);
            statVol(col) = 100 * sqrt(frequency) * std(assetSimpleRets);
            statSkew(col) = skewness(assetSimpleRets);
            statKurt(col) = kurtosis(assetSimpleRets);
            statWorst(col) = min(assetSimpleRets);
            statBest(col) = max(assetSimpleRets);
        end
    end
    
    colNames = [{'Entity'} {'Years'} {'SR'} {'Ret p.a.'} {'Worst'}  {'Best'} {'Vol p.a.'} {'Skew'} {'Kurt'}];
    rowNames = simpleRets.Properties.VariableNames';
    tableData = string([round(years) round([statSR statReturns statWorst statBest statVol statSkew statKurt]*100)/100]);
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
    windowRets = returns(idxFrom:idxTo, :);
end
