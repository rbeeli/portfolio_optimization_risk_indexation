function funcs = liblog()
    funcs.writeTo = @writeTo;
end


function writeTo(str, path)
    % Replace …  with .. to preserve equal spacing
    str = strrep(str, '…', '..');
    
    fileID = fopen(path, 'w');
    fprintf(fileID, str);
    fclose(fileID);
end