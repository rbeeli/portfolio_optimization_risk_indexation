clc
clear
close all force


% load data
[returns, cumReturns] = read_lecture_dataset();


% plot returns of asset classes
figure

subplot(5, 1, 1)
plot(cumReturns.Datum, cumReturns{:, 2})
legend(cumReturns.Properties.VariableNames{2}, 'Interpreter','none', 'Location','northwest')
title('Cash')

subplot(5, 1, 2)
plot(cumReturns.Datum, cumReturns{:, 2:6})
legend(cumReturns.Properties.VariableNames{2:6}, 'Interpreter','none', 'Location','northwest')
title('Bonds')

subplot(5, 1, 3)
plot(cumReturns.Datum, cumReturns{:, 7:10})
legend(cumReturns.Properties.VariableNames{7:10}, 'Interpreter','none', 'Location','northwest')
title('Equities')

subplot(5, 1, 4)
plot(cumReturns.Datum, cumReturns{:, 11:12})
legend(cumReturns.Properties.VariableNames{11:12}, 'Interpreter','none', 'Location','northwest')
title('Alternative')

subplot(5, 1, 5)
plot(cumReturns.Datum, cumReturns{:, 13})
legend(cumReturns.Properties.VariableNames{13}, 'Interpreter','none', 'Location','northwest')
title('Commodities')


