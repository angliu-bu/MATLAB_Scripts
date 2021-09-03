clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');

% --------------- Data recording parameters -------------------------------

file_base = ['ConductivityTest_' date '_volumeMeasurement_100upm'];
file_headers = sprintf('# Time [s]\tRealPart[V]\tImagPart[V]\tMagnitude[V]\tFlowRate[uL/min]\n');

initial_notes = ...
    ['# This is a differential measurement of the conductivities at the two\n' ...
    '# different salt sensors. Starting with salty water and filling channel\n' ...
    '# with DI water. Flow rate is set to 100 uL/min. Purpose is to clean channel.\n'];

% Generate folder withe name yyyy-mm-dd. Format ensures that folders are
% listed chronologically when sorted by name.
folder = sprintf('Data/%4.0f-%02.0f-%02.0f',year(date),month(date),day(date));

% Create dated folder if it doesn't already exist
if exist(folder) == 0
    mkdir(folder)
    fprintf('Folder /%s/ created.\n',folder);
end

% Prevent overwriting file by incrementing trailing number if filename
% already exists
i = 1;
file_exists = true;
while file_exists
    filename = [folder '/' file_base '_' num2str(i) '.txt'];
    file_exists = boolean(exist(filename)) ~= 0;
    i = i+1;
end

fprintf('New save file:\n%s\n',filename);
fileID = fopen(filename,'w');
fprintf(fileID, initial_notes);
fprintf(fileID, file_headers);

% --------------- Define and connect to all equipment ---------------------
lock_in = SR844_LockIn;
%multimeter = HP3478A_Multimeter;
pump = ChemyxSyringePump;

lock_in.open;
%multimeter.open;
pump.open;
% -------------------------------------------------------------------------



% ----------------- Set Syringe pump parameters ---------------------------

pump.set_units(2);
pump.set_volume(-2000);
pump.set_rate(100);

% -------------------------------------------------------------------------

% Record start time of experiment
start_time = now*86400;

% Create data matrix for plotting
data = [];

% Define what happens when key is pressed. To be used for killing loop.
h=figure('KeyPressFcn','keep=0');
keep = 1;

pump.start;

pause(0.5);
while keep == 1
    % Record desired results
    pump_status = pump.get_status;
    if pump_status == 1
        flow_rate = pump.rate;
    else
        flow_rate = 0;
    end
    
    results = [86400*now - start_time ...
        lock_in.read_real ...
        lock_in.read_imaginary ...
        lock_in.read_magnitude ...
        flow_rate ...
        ];
    
    % Write new results to file.
    fprintf(fileID,'%.10f\t%.10f\t%.10f\t%.10f\t%f\n', ...
        results(1),results(2),results(3),results(4),results(5));
    
    % Append latest results to data matrix
    data = [data; results];
    
    plot(data(:,1),data(:,2),data(:,1),data(:,3),data(:,1),data(:,4));
    
    % Give computer time to detect keystroke.
    pause(0.005);
end

pump.stop;

% Close data file
fclose(fileID);

% ------------------- Close connections to equipment ----------------------
lock_in.close;
%multimeter.close;
pump.close;
% -------------------------------------------------------------------------

fclose('all');