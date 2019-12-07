% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

function funcs = libvisualize()
    funcs.plotReturns = @plotReturns;
    funcs.plotWeights = @plotWeights;
    funcs.newFigure = @newFigure;
    funcs.setPrintOptions = @setPrintOptions;
    funcs.printFigure = @printFigure;
    funcs.calcGridSize = @calcGridSize;
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
    if size(returns, 2) <= 20
        if isempty(labels)
            labels = returns.Properties.VariableNames;
        end

        legend(labels, 'Interpreter','none', 'Location','NorthWest');
    end
    
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
    xlim([0 size(wgts, 1)]);
    ylim([0 100]);
    
    % legend
    if size(wgts, 2) <= 20
        if ~isempty(labels)
            legend(labels, 'Location', 'NorthEastOutside')
        end
    end
    
    % title
    title(plotTitle)
    
    % y-axis ticks/labels
    set(gca, 'YTick', 0:20:100)
    if ~isempty(yAxisLabel)
        ylabel(yAxisLabel);
    end

    % x-axis ticks/labels (year)
    ticks = 1:(floor(size(wgts, 1) / 12)):size(wgts, 1);
    set(gca, 'XTick', ticks)
    set(gca, 'XTickLabel', datestr(wgts.Date(ticks), 'yyyy'))
end


function f = newFigure(titleStr, x, y, width, height)
    f = figure('Name',titleStr, 'NumberTitle','off', 'Position', [x y width height]); 
end


function setPrintOptions(fig)
    % print options to reflect window sizing
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
end


function printFigure(fig, path)
    print(fig, '-dpdf', '-painters', path);
end


function [x, y] = calcGridSize(N)
    if N == 2
        x = 2;
        y = 1;
    elseif N == 6
        x = 3;
        y = 2;
    else
        x = ceil(sqrt(N));
        y = ceil(sqrt(N));
    end
end

