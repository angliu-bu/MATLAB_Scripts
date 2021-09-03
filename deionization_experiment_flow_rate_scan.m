clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');

% --------------- Data recording parameters -------------------------------

file_base = ['ConductivityTest_' date];
file_headers = sprintf('# Time [s]\tRealPart[V]\tImagPart[V]\tMagnitude[V]\tFlowRate[uL/min]\n');

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
fprintf(fileID, file_headers);

% --------------- Define and connect to all equipment ---------------------
lock_in = SR844_LockIn;
multimeter = HP3478A_Multimeter;
pump = ChemyxSyringePump;

lock_in.open;
multimeter.open;
pump.open;
% -------------------------------------------------------------------------



% ----------------- Set Syringe pump parameters ---------------------------

pump.set_units(2);
pump.set_volume(-10000);
pump.set_rate(100);

% -------------------------------------------------------------------------

% Record start time of experiment
start_time = now*86400;

% Create data matrix for plotting
data = [];

pump.start;

pause(0.5);

iteration_volume = 200; % Volume in microliters for each iteration in loop

new_start = start_time;

for curr_rate = [1000 500 300 200 100 50 30 20 10 5 3 2 1]
    time = 86400*now - start_time;
    new_start = time;
    fprintf('Current flow rate: %f\n',curr_rate);
    pump.set_rate(curr_rate);
    pause(0.5);
    while time - new_start < 60*iteration_volume / curr_rate
        % Record desired results
        time = 86400*now - start_time;
        results = [time ...
            lock_in.read_real ...
            lock_in.read_imaginary ...
            lock_in.read_magnitude ...
            curr_rate ...
            ];
        
        % Write new results to file.
        fprintf(fileID,'%.10f\t%.10f\t%.10f\t%.10f\t%f\n', ...
            results(1),results(2),results(3),results(4),results(5));
        
        % Append latest results to data matrix
        data = [data; results];
        
        plot(data(:,1),data(:,2),data(:,1),data(:,3),data(:,1),data(:,4));
        
    end
end

pump.stop;

% Close data file
fclose(fileID);

% ------------------- Close connections to equipment ----------------------
lock_in.close;
multimeter.close;
pump.close;
% -------------------------------------------------------------------------

fclose('all');