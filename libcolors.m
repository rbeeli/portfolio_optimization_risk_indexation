% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

function funcs = libcolors()
    funcs.distinctColors = @distinctColors;
    funcs.gradientColors = @gradientColors;
    funcs.parseRgbString = @parseRgbString;
end


function colors = distinctColors(count)
    persistent distinctPalette
    
    if isempty(distinctPalette)
        distinctPalette = 1/255 .* [
            [0,0,0]; [215,40,15]; [20,95,190]; [0,138,22];
            [240,195,0]; [60,30,115]; [0,135,240]; [140,190,40];
            [255,170,3]; [250,80,35]; [185,0,170]; [90,30,200];
            [220,85,45]; [245,125,65]; [205,0,110]; [100,30,100];
            [38,227,222]; [0,160,177]; [105,50,190]
        ];
    end

    if size(distinctPalette, 1) < count
        colors = hsv(count);  % fallback if too many colors requested
    else
        colors = distinctPalette(1:count, :);
    end
end


function colors = gradientColors(count)
    persistent gradientPalette
    
    if isempty(gradientPalette)
        % source: http://colrd.com/palette/40366/
        gradientPalette = 1/255 .* [
            [20,0,85]; [0,85,190]; [0,135,240]; [0,190,240];
            [38,227,222]; [10,185,190]; [0,160,177]; [0,138,22];
            [0,155,0]; [140,190,40]; [255,215,0]; [255,170,3];
            [245,125,65]; [220,85,45]; [250,80,35]; [215,40,15];
            [205,0,110]; [185,0,170]; [100,30,100]; [70,40,125];
            [105,50,190]; [80,20,200];
        ];
    end
    
    if size(gradientPalette, 1) < count
        colors = hsv(count);  % fallback if too many colors requested
    else
        colors = gradientPalette(1:count, :);
    end
end


function c = parseRgbString(rgbString, normalize)
    parts = split(replace(replace(rgbString, 'rgb(', ''), ')', ''), ',');
    c = [str2double(parts(1)), str2double(parts(2)), str2double(parts(3))];
    
    if normalize
       c = c / 255.0;
    end
end












