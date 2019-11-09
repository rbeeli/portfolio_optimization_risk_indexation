function[] = SumStats()

% This function calculates summary statistics and plots 
% return distributions for sample "Indices"
%
% Required Inputs are:
% - (T x N) matrix of index values, where T = number of observations, 
%    N = number of asset classes
% - (T x 1) vector with dates, e.g. '31.01.1993'
% - (N x 1) vector of asset class names
%
% October 2010, Ph. Rohner


%% Input Parameters

close all % close all open figures

dateStart = datenum('31.12.1999','dd.mm.yyyy');
dateEnd = datenum('31.08.2017','dd.mm.yyyy');
showTS = 'on'; % Display chart with asset class time series: 'on' or 'off'
showDist = 'on'; % Display chart with asset class time series: 'on' or 'off'
tickSpace = 5; % number of dates on x-axis

%% load data file

load returns2019_homebias.mat
%Names = Names(5:11,:);
%Returns = Returns(:,5:11);
[dummy numAC] = size(Returns);
datesVal = datenum(Dates);
%% Select Sample Period and calculate returns
for j = 1:numAC
    dummy = Returns(:,j);
    Ret(:,j) = dummy((datesVal >= dateStart) & (datesVal <= dateEnd));
end
Dat = datesVal((datesVal >= dateStart) & (datesVal <= dateEnd));
[numVal numAC] = size(Ret);


Ind100(1,1:numAC) = 100;
for j = 2:numVal
    Ind100(j,:) = Ind100(j-1,:).*(1 + Ret(j,:));
end

switch showTS
    case 'on'
        plot(Ind100,'LineWidth',1.5);
        legend(Names,'Location','Northwest')
        ticks = round(1:((numVal - 1)/tickSpace):numVal);
        xTickNames = Dat(ticks);
        set(gca,'XTick',ticks)
        set(gca,'XTickLabel',datestr(xTickNames,12))
        axis([1,length(Ind100), 0, max(max(Ind100))])
    case 'off'
    otherwise
end

%% Calculate Summary Stats

Returns = round((((((Ind100(numVal,:)./Ind100(1,:)).^(12/(numVal-1))) - 1)*100)')*100)/100;
Vols = round((((std(Ret)*sqrt(12))*100)')*100)/100;
Skew = round((skewness(Ret)')*100)/100;
Kurt = round((kurtosis(Ret)')*100)/100;

colNames = [{'Ret p.a.'} {'Vol p.a.'} {'Skew'} {'Kurt'}];
rowNames = Names;
Data = num2cell([Returns Vols Skew Kurt]);
Table = [{'Asset Class'} colNames; rowNames Data]



%% Plot Return Distributions
switch showDist
    case 'on'
        for j = 1:length(Names)

            [f,xi] = ksdensity(Ret(:,j));
            y = normpdf(xi, mean(Ret(:,j)), std(Ret(:,j)));

            figure(j+1)
            %[f,xi] = ksdensity(Ret(:,j));
            plot(xi,f, 'LineWidth', 2);
            hold on
            plot(xi,y,'red','LineWidth',2)
            legend('Empirical','Normal','Location','NW')
            title(Names{j},'FontSize',12)
        end
    case 'off'
    otherwise
end


        
            
            
            
            
            
            


