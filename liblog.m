function funcs = liblog()
    funcs.writeTo = @writeTo;
    funcs.toString = @toString;
end


function str = toString(object, sanitize)
    % get string by printing object to console and retrieve output
    str = evalc("disp(object)");
    
    if sanitize
        % replace …  with .. to preserve equal spacing
        str = strrep(str, '…', '..');
        str = strrep(str, '"', '');
        str = strrep(str, "'", '');
    end
end


function writeTo(str, path)
    % writes the given as text to the path supplied.
    fileID = fopen(path, 'w');
    fprintf(fileID, str);
    fclose(fileID);
end
