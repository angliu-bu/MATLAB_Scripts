function [new_file, filename, folder]=name_file(file_base,extension,folder)
    if nargin < 3
        % Generate folder withe name yyyy-mm-dd. Format ensures that folders are
        % listed chronologically when sorted by name.
        folder = sprintf('Data/%4.0f-%02.0f-%02.0f',year(date),month(date),day(date));
    end
    if nargin < 2
        % Assume file will be output as a text file
        extension = '.txt';
    end
    
    % Create dated folder if it doesn't already exist
    if exist(folder) == 0
        mkdir(folder);
        fprintf('Folder /%s/ created.\n',folder);
    end
    
    % Number all files based on which run of the day it is. Helps to document
    % order in which experiments were performed.
    file_list = dir(folder);
    
    if numel(file_list) > 2
        last_number = str2double(file_list(end).name(1:4));
    else
        last_number = 0;
    end
    file_base = sprintf('%04.0f_%s',last_number+1,file_base);
    
    filename = [folder '/' file_base extension];
     
    fprintf('New save file:\n%s\n',filename);
    new_file = fopen(filename,'w');
    
end
