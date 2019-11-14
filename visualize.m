function funcs = visualize()
    funcs.plotReturns = @plotReturns;
end


function plotReturns(plotTitle, returns)
    nColumns = size(returns, 2);
    colors = getColors(nColumns);

    % log-plot
    for c=1:nColumns
        semilogy(returns.Date, returns{:, c}, 'Color', colors(c, :));
        hold on;
    end

    title(plotTitle);
    ylabel('log-returns');
    
    % legend
    if nColumns < 20
        [~, hobj, ~, ~] = legend(returns.Properties.VariableNames, 'Interpreter','none', 'Location','NorthEastOutside');
        hl = findobj(hobj, 'type','line');
        set(hl, 'LineWidth', 2);
    end
end


function colors = getColors(count)
    % define colors
    nColors = count + 3;
    t = linspace(0, 1, nColors)';
    s = 0.75 * ones(nColors, 1);
    v = 0.80 * ones(nColors, 1);
    colors = colormap(squeeze(hsv2rgb(t,s,v)));
    colors = colors(1:count, :);
end