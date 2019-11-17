function[] = doBacktest()
% This function conducts an out-of-sample backtest for different investment
% strategies
%
%
% Required Inputs are:
% - (T x N) matrix of returns, where T = number of observations, N = number of asset classes
% - (T x 1) vector with dates
% - (N x 1) vector of asset class names
%
%
% First Version: January 2014, Ph. Rohner
% Last Update: October 2019, Ph. Rohner


%% Input Parameters

close all force
%clc


dateStart = datenum('31.01.1972','dd.mm.yyyy');
dateEnd = datenum('31.12.2019','dd.mm.yyyy');
method = 'constr'; % select 'constr = no short-selling' or 'unconstr = short selling allowed' for mv-optimization
estPeriod = 60; % length of estimation period (in months)
rebalPeriod = 12; %number of months until recalculation, e.g.: 1 = monthly; 3 = quarterly; 12 = annual
showAA = 5; % integer between  1 and N. Indicates strategy to be shown in AA plot

obsYear = 12; % 12 for monthly data
numPort = 30; % number of portfolios in the efficient frontier
benchmarkAC = 1; % integer between 1 and N. Indicates position of benchmark asset class
targetVol = 0.09; % specify target volatility for 'constant vol strategy'
targetPremium = 0.2; % specify target risk premium for 'constant return strategy'

namesPort = {'1/n BH' '1/n Reb' 'Min Var' 'max SR' 'Const Ret' 'Const Vol' 'Benchmark'};
tickSpace = 6; % number of dates on x-axis


%% load data file

load returns2019_major.mat
[dummy numAC] = size(Returns);
datesVal = datenum(Dates);


%% Select Sample Period and calculate asset class returns
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


ret = Ind100(2:numVal,:)./Ind100(1:numVal-1,:) - 1;
numTesting = length(ret(:,1)) - estPeriod;


%% Calculate Portfolio Returns

indNaive = zeros(numTesting + 1, 1);
indBH = zeros(numTesting + 1, 1);
indMinVar = zeros(numTesting + 1, 1);
indSR = zeros(numTesting + 1, 1);
indBM = zeros(numTesting + 1, 1);
indCRet = zeros(numTesting + 1, 1);
indCVol = zeros(numTesting + 1, 1);
wtsNaive = zeros(numTesting, numAC);
wtsBH = zeros(numTesting, numAC);
wtsMinVar = zeros(numTesting, numAC);
wtsSR = zeros(numTesting, numAC);
wtsCRet = zeros(numTesting, numAC);
wtsCVol = zeros(numTesting, numAC);
retNaive = zeros(numTesting, 1);
retBH = zeros(numTesting, 1);
retMinVar = zeros(numTesting, 1);
retSR = zeros(numTesting, 1);
retBM = zeros(numTesting, 1);
retCRet = zeros(numTesting, 1);
retCVol = zeros(numTesting, 1);
AANaive = zeros(numTesting,numAC);
AABH = zeros(numTesting,numAC);
AAMinVar = zeros(numTesting,numAC);
AASR = zeros(numTesting,numAC);
AACRet = zeros(numTesting,numAC);
AACVol = zeros(numTesting,numAC);

retTesting = ret(estPeriod + 1:estPeriod + numTesting,:);
dummy1 = 1:1:numTesting;
dummy2 = 1:rebalPeriod:floor(numTesting/rebalPeriod)*rebalPeriod + rebalPeriod;
vecRebal = ismember(dummy1, dummy2)';

% Calculate constant weight portfolios
indNaive(1,:) = 100;
indBH(1,:) = 100;
wtsNaive(1,:) = ones(1,numAC)*(1/numAC);
AANaive(1,:) = wtsNaive(1,:);
wtsBH(1,:) = ones(1,numAC)*(1/numAC);
AABH(1,:) = wtsBH(1,:);
retNaive(1,1) = wtsNaive(1,:)*retTesting(1,:)';
retBH(1,1) = wtsBH(1,:)*retTesting(1,:)';

for i1 = 2:numTesting
    
    dummyBH = wtsBH(i1-1,:).*(1 + retTesting(i1,:));
    wtsBH(i1,:) = dummyBH./sum(dummyBH);
    AABH(i1,:) = wtsBH(i1,:);
    retBH(i1,1) = wtsBH(i1,:)*retTesting(i1,:)';

    if vecRebal(i1,1) == 1;
        wtsNaive(i1,:) = ones(1,numAC)*(1/numAC);
        retNaive(i1,1) = wtsNaive(i1,:)*retTesting(i1,:)';
        AANaive(i1,:) = wtsNaive(i1,:);
    else
        dummyNaive = wtsNaive(i1-1,:).*(1 + retTesting(i1,:));
        wtsNaive(i1,:) = dummyNaive./sum(dummyNaive);
        retNaive(i1,1) = wtsNaive(i1,:)*retTesting(i1,:)';
        AANaive(i1,:) = wtsNaive(i1,:);
    end
end


% Calculate optimized portfolios

indMinVar(1,:) = 100;
indSR(1,:) = 100;
indCRet(1,:) = 100;
indCVol(1,:) = 100;

h = waitbar(0,'calc portfolio weights...') 


i3 = 1;
    ExpRet = ((1 + mean(ret(i3:estPeriod + i3 -1,:))).^(obsYear) - 1)';
    CovMat = cov(ret(i3:estPeriod + i3 -1,:))*obsYear;
    rf = mean(riskFree(i3:estPeriod + i3 -1,1))*12;
    
    [frontWts, frontRet, frontVol] = MeanVarianceOptimization(ExpRet, CovMat, numPort, method);

    % Minimum Variance Portfolio
    wtsMinVar(i3,:) = frontWts(:,1)';
    retMinVar(i3,1) = wtsMinVar(i3,:)*retTesting(i3,:)';
    AAMinVar(i3,:) = wtsMinVar(i3,:);
    
    % Max Sharpe Ratio Portfolio
    maxSR = (frontRet - rf)./frontVol;
    vec = 1:1:length(maxSR);
    portSR = vec(maxSR == max(maxSR))
    wtsSR(i3,:) = frontWts(:,portSR)';
    retSR(i3,1) = wtsSR(i3,:)*retTesting(i3,:)';
    AASR(i3,:) = wtsSR(i3,:);
    
    % Constant Return
    targetRet = (rf + targetPremium);
    if targetRet > max(frontRet)
        portCR = max(vec);
    elseif targetRet < min(frontRet)
        portCR = min(vec);
    elseif targetRet >= min(frontRet) && targetRet <= max(frontRet)
        portCR = max(vec(frontRet <= targetRet));
    end
    
    wtsCRet(i3,:) = frontWts(:,portCR)';
    retCRet(i3,1) = wtsCRet(i3,:)*retTesting(i3,:)';
    AACRet(i3,:) = wtsCRet(i3,:);
    
    % Constant Volatility
    if targetVol > max(frontVol)
        portCV = max(vec);
    elseif targetVol < min(frontVol)
        portCV = min(vec);
    elseif targetVol >= min(frontVol) && targetVol <= max(frontVol)
        portCV = max(vec(frontVol <= targetVol));
    end
    
    wtsCVol(i3,:) = frontWts(:,portCV)';
    retCVol(i3,1) = wtsCVol(i3,:)*retTesting(i3,:)';
    AACVol(i3,:) = wtsCVol(i3,:);
    TestWts(1,:)=frontWts(:,15)';

for i3 = 2:numTesting
    waitbar(i3 / numTesting)
    
    if vecRebal(i3,1) == 1;
        
    
        ExpRet = ((1 + mean(ret(i3:estPeriod + i3 -1,:))).^(obsYear) - 1)';
        CovMat = cov(ret(i3:estPeriod + i3 -1,:))*obsYear;
        rf = mean(riskFree(i3:estPeriod + i3 -1,1))*12;

        [frontWts, frontRet, frontVol] = MeanVarianceOptimization(ExpRet, CovMat, numPort, method);
        TestWts(i3,:)=frontWts(:,15)';
        

        
        % Minimum Variance Portfolio
        wtsMinVar(i3,:) = frontWts(:,1)';
        retMinVar(i3,1) = wtsMinVar(i3,:)*retTesting(i3,:)';
        AAMinVar(i3,:) = wtsMinVar(i3,:);

        % Max Sharpe Ratio Portfolio
        maxSR = (frontRet - rf)./frontVol;
        vec = 1:1:length(maxSR);
        port = vec(maxSR == max(maxSR));
        wtsSR(i3,:) = frontWts(:,port)';
        retSR(i3,1) = wtsSR(i3,:)*retTesting(i3,:)';
        AASR(i3,:) = wtsSR(i3,:);
        
         hold on
         figure(5)
         plot(frontVol, frontRet)
         hold on
         plot(frontVol(port,1),frontRet(port,1),'o','markersize',2,'MarkerEdgeColor','red','MarkerFaceColor','black','linewidth',3,'linestyle','none')
         xlabel('Expected Risk (Volatility)','FontSize',12)
         ylabel('Expected Return','FontSize',12)
         title('Efficient Frontiers over time' ,'FontSize',12)
         grid on
        
        % Constant Return Portfolio
        targetRet = (rf + targetPremium);
        if targetRet > max(frontRet)
            portCR = max(vec);
        elseif targetRet < min(frontRet)
            portCR = min(vec);
        elseif targetRet >= min(frontRet) && targetRet <= max(frontRet)
            portCR = max(vec(frontRet <= targetRet));
        end

        wtsCRet(i3,:) = frontWts(:,portCR)';
        retCRet(i3,1) = wtsCRet(i3,:)*retTesting(i3,:)';
        AACRet(i3,:) = wtsCRet(i3,:);
    
        % Constant Volatility Portfolio
        if targetVol > max(frontVol)
            portCV = max(vec);
        elseif targetVol < min(frontVol)
            portCV = min(vec);
        elseif targetVol >= min(frontVol) && targetVol <= max(frontVol)
            portCV = max(vec(frontVol <= targetVol));
        end

        wtsCVol(i3,:) = frontWts(:,portCV)';
        retCVol(i3,1) = wtsCVol(i3,:)*retTesting(i3,:)';
        AACVol(i3,:) = wtsCVol(i3,:);
        
    else
        dummyMinVar = wtsMinVar(i3-1,:).*(1 + retTesting(i3,:));
        wtsMinVar(i3,:) = dummyMinVar./sum(dummyMinVar); 
        retMinVar(i3,1) = wtsMinVar(i3,:)*retTesting(i3,:)';
        AAMinVar(i3,:) = wtsMinVar(i3,:);
        
        dummySR = wtsSR(i3-1,:).*(1 + retTesting(i3,:));
        wtsSR(i3,:) = dummySR./sum(dummySR); 
        retSR(i3,1) = wtsSR(i3,:)*retTesting(i3,:)';
        AASR(i3,:) = wtsSR(i3,:);
        
        dummyCRet = wtsCRet(i3-1,:).*(1 + retTesting(i3,:));
        wtsCRet(i3,:) = dummyCRet./sum(dummyCRet); 
        retCRet(i3,1) = wtsCRet(i3,:)*retTesting(i3,:)';
        AACRet(i3,:) = wtsCRet(i3,:);
        
        dummyCVol = wtsCVol(i3-1,:).*(1 + retTesting(i3,:));
        wtsCVol(i3,:) = dummyCVol./sum(dummyCVol); 
        retCVol(i3,1) = wtsCVol(i3,:)*retTesting(i3,:)';
        AACVol(i3,:) = wtsCVol(i3,:);
        
        TestWts(i3,:)= TestWts(i3-1,:);
    end
    
end
close(h)

indBM(1,:) = 100;

for i2 = 2:numTesting + 1
    
    indBH(i2,1) = indBH(i2 - 1,1)*(1 + retBH(i2 - 1,1));
    indNaive(i2,1) = indNaive(i2 - 1,1)*(1 + retNaive(i2 - 1,1));
    indMinVar(i2,1) = indMinVar(i2 - 1,1)*(1 + retMinVar(i2 - 1,1));
    indSR(i2,1) = indSR(i2 - 1,1)*(1 + retSR(i2 - 1,1));
    indCRet(i2,1) = indCRet(i2 - 1,1)*(1 + retCRet(i2 - 1,1));
    indCVol(i2,1) = indCVol(i2 - 1,1)*(1 + retCVol(i2 - 1,1));
    indBM(i2,1) = indBM(i2 - 1,1)*(1 + retTesting(i2 - 1,benchmarkAC));
    
end


%% Calculate Summary Statistics

returns = [retBH retNaive retMinVar retSR retCRet retCVol retTesting(:,benchmarkAC)];
indices = [indBH indNaive indMinVar indSR indCRet indCVol indBM];
retAnnual = (1 + mean(returns)).^(obsYear)-1;
volAnnual = std(returns)*sqrt(obsYear);
[maxDD] = calcMaxDD(indices);
data = num2cell([retAnnual*100; volAnnual*100; (retAnnual./volAnnual); skewness(returns); kurtosis(returns); maxDD']);
namesCat = {'Ret[%]'; 'Vol[%]'; 'Ret/Vol'; 'Skew'; 'Kurt'; 'maxDD'};

SummaryStats = [{'Statistic'} namesPort; namesCat data]



%% Create Data Plots

% Horse Race
indPortfolios = [indBH indNaive indMinVar indSR indCRet indCVol];


[numTest numAC] = size(indPortfolios);
datTest = Dat(estPeriod+1:estPeriod + numTest,1);

figure(2)
plot(indPortfolios,'LineWidth',1.5)
legend(namesPort, 'Location', 'NorthWest','FontSize',12) 
title('Horse Race: Portfolios over Time','FontSize',12)
ylabel('Index','FontSize',12)
ticks = round(1:((numTest-1)/tickSpace):numTest);
xTickNames = datTest(ticks);
set(gca,'XTick',ticks)
set(gca,'XTickLabel',datestr(xTickNames,12))
grid on


% Select strategy to plot
if showAA == 1;
    AA = AABH;
elseif showAA == 2;
    AA = AANaive;
elseif showAA == 3;
    AA = AAMinVar;
elseif showAA == 4;
    AA = AASR;
elseif showAA == 5;
    AA = AACRet;
elseif showAA == 6;
    AA = AACVol;
end

        figure(3)
        area(AASR)
        legend(Names, 'Location', 'NorthEastOutside')
        title(namesPort(1,4))
        ylabel('Portfolio Fraction')
        axis([1 numTest-1 0 1])
        set(gca,'XTick',ticks)
        set(gca,'XTickLabel',datestr(xTickNames,12))
        
        
switch method
    case 'unconstr'
        figure(4)
        plot(AA)
        legend(Names,'Location', 'NorthEastOutside')
        title(namesPort(1,showAA))
        ylabel('Portfolio Fraction')
        set(gca,'XTick',ticks)
        set(gca,'XTickLabel',datestr(xTickNames,12))
            
    case 'constr'
        
        figure(4)
        area(AA)
        title(namesPort(1,showAA))
        legend(Names, 'Location', 'NorthEastOutside')
        ylabel('Portfolio Fraction')
        axis([1 numTest-1 0 1])
        set(gca,'XTick',ticks)
        set(gca,'XTickLabel',datestr(xTickNames,12))
end



function[maxDD] = calcMaxDD(Index)
    
[T,N] = size(Index);
maxDD = zeros(N,1);
DD = zeros(T,N);
for ACi = 1:N
    for t = 2:T
        if max(Index(1:t,ACi)) > Index(t,ACi)
            DD(t,ACi) = Index(t,ACi)/max(Index(1:t,ACi)) - 1;
        else
        end
    end
    maxDD(ACi,1) = min(DD(:,ACi))*100;
end


function[frontWts, frontRet, frontVol] = MeanVarianceOptimization(ExpRet, CovMat, numPort, method)
   numAssets = length(ExpRet);
    V0 = zeros(1, numAssets);
    V1 = ones(1, numAssets);

    % Set constraints
    
    UB = ones(numAssets,1);
    
    switch method
        case 'unconstr'
            LB = ones(numAssets,1)*(-1);
            
        case 'constr'
            LB = zeros(numAssets,1);
    end
    
    % Define inequality constraints
    
    A1 = zeros(1,numAssets);
    A2 = zeros(1,numAssets); 
    A = [A1; A2];
    b = [0.; 1];
    
    % Find minimum variance return
    minVarWts = quadprog(CovMat, V0, A, b, V1, 1, LB);
    minVarRet = minVarWts'*ExpRet;
    minVarVol = sqrt(minVarWts'*CovMat*minVarWts);
    
    % Find maximum return
    maxRetWts = quadprog([], -ExpRet, A, b, V1, 1, LB);
    maxRet = maxRetWts'*ExpRet;
    
    
    % Calculate frontier portfolios
    targetRet = linspace(minVarRet, maxRet, numPort);
    frontRet = zeros(numPort,1);
    frontVol = zeros(numPort,1);
    frontWts = zeros(numAssets, numPort)
    
    frontRet(1,1) = minVarRet;
    frontVol(1,1) = minVarVol;
    frontWts(:,1) = minVarWts;
    
    Aeq = [V1; ExpRet'];

    
    for i = 2:numPort
        beq = [1; targetRet(i)];
        weights = quadprog(CovMat, V0, A, b, Aeq, beq, LB, UB);
        frontRet(i,1) = weights'*ExpRet;
        frontVol(i,1) = sqrt(weights'*CovMat*weights);
        frontWts(:,i) = weights;
    end




