function funcs = libvisualize()
    funcs.plotReturns = @plotReturns;
    funcs.plotWeights = @plotWeights;
    funcs.newFigure = @newFigure;
end


function plotReturns(plotTitle, returns, labels, yAxisLabel, colorFunc)
    nColumns = size(returns, 2);
    colors = colorFunc(nColumns);

    % log-plot
    for c=1:nColumns
%         plot(returns.Date, returns{:, c}, 'Color',colors(c, :), 'LineWidth',1.3);
        semilogy(returns.Date, returns{:, c}, 'Color',colors(c, :), 'LineWidth',1.3);
        hold on;
    end

    % title
    title(plotTitle);
    
    % y-axis label
    if ~isempty(yAxisLabel)
        ylabel(yAxisLabel);
    end
    
    % legend
    if isempty(labels)
        labels = returns.Properties.VariableNames;
    end

    legend(labels, 'Interpreter','none', 'Location','NorthWest');
    
%     % x-axis tick labels (year)
%     ticks = 1:(floor(size(returns, 1) / 12)):size(returns, 1);
%     set(gca, 'XTick', ticks)
%     set(gca, 'XTickLabel', datestr(returns.Date(ticks), 'yyyy'))
end


function plotWeights(plotTitle, wgts, labels, yAxisLabel, colorFunc)
    nColumns = size(wgts, 2);
    colors = colorFunc(nColumns);
    
    % area
    h = area(wgts{:, :} .* 100, 'LineStyle','none');
    for c=1:size(colors, 1)
        h(c).FaceColor = colors(c, :);
    end
    
    % axis ranges
    axis([0 size(wgts, 1) 0 100])
    
    % legend
    if ~isempty(labels)
        legend(labels, 'Location', 'NorthEastOutside')
    end
    
    % title
    title(plotTitle)
    
    % y-axis label
    if ~isempty(yAxisLabel)
        ylabel(yAxisLabel);
    end

    % x-axis tick labels (year)
    ticks = 1:(floor(size(wgts, 1) / 12)):size(wgts, 1);
    set(gca, 'XTick', ticks)
    set(gca, 'XTickLabel', datestr(wgts.Date(ticks), 'yyyy'))
end


function f = newFigure(titleStr, maximize)
    f = figure('Name',titleStr, 'NumberTitle','off');
    
    if nargin > 1 && maximize
       f.WindowState = 'maximized';
    end
end