clear, clc, instrreset;
a = arduino;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');

file_base = ['MultiplexerTest_' date '_15ms_Pause'];
file_headers = sprintf('# Time [s]\tRealPart[V]\n');

initial_notes = ...
    ['# \n' ...
    ];


% ------------------------ File operations ---------------------------
% Generate folder withe name yyyy-mm-dd. Format ensures that folders are
% listed chronologically when sorted by name.
folder = sprintf('Data/%4.0f-%02.0f-%02.0f',year(date),month(date),day(date));

% Create dated folder if it doesn't already exist
if exist(folder) == 0
    mkdir(folder)
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

% Prevent overwriting file by incrementing trailing number if filename
% already exists
i = 1;
filename = [folder '/' file_base '.txt'];
while boolean(exist(filename)) ~= 0
    filename = [folder '/' file_base '_' num2str(i) '.txt'];
    i = i+1;
end

fprintf('New save file:\n%s\n',filename);
fileID = fopen(filename,'w');
fprintf(fileID, initial_notes);
fprintf(fileID, file_headers);

%-------------------------------------------------------------------------

lockin = SR844_LockIn;
lockin.open;


start_time = now*86400;
time = 0;
delay_time = 0.015;

measurement1 = [];
measurement2 = [];



data = [];

while time < 20
    time = now*86400 - start_time;

    writeDigitalPin(a,'D2',0);
    writeDigitalPin(a,'D3',0);
    pause(delay_time);
    
    
    writeDigitalPin(a,'D2',1);
    writeDigitalPin(a,'D3',0);
    pause(delay_time);
    
    writeDigitalPin(a,'D2',0);
    writeDigitalPin(a,'D3',1);
    pause(delay_time);
    data = [data; time lockin.read_real];
    
    fprintf(fileID,'%.10f\t%.10f\n',data(end,1),data(end,2));
    plot(data(:,1),data(:,2));
end

lockin.close;
fclose(fileID);

%%

s = daq.createSession('ni');