clear, clc, instrreset;
cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');


% ----------------------  Operational Parameters  -------------------------
% These are the user-defined operation parameters for the network analyzer.
% Note that if any of these parameters conflict with each other (i.e., the
% sweep time is too small for the bandwidth, etc.) the network analyzer
% will over-write the value

device_description = 'Piezo1_C06_vacuum';

f_start = 365e6;    % Start Frequency in Hz
f_stop  = 368e6;    % Stop frequency in Hz
power   = 16;        % Power in dBm
S_parameter1 = 'S21'; % Set meas1 s-parameter
%S_parameter2 = 'S21'; % Set meas2 s-parameter

n_subsweeps = 1; % Number of sweeps to break data file into
n_points = 1601; % Number of points per sweep

res_BW = 250;            % Bandwidth
n_aver = 1;             % Number of times to average
averaging = 'OFF';      % Averaging state
sweep_time = 'AUTO';    % Time per subsweep
trace1_type = 'MLIN';    % Set trace1 format
%trace2_type = 'IMAG';    % Set trace2 format


% -------------------------------------------------------------------------

deltaF = (f_stop-f_start)/n_subsweeps;
   
    




%for power=9:-3:-60
%for n_iter=1:16

instrreset;

%fprintf("Current iteration\nPower: %d dBm\tIteration: %d\n",power,n_iter);

% ---------------------------  File naming  -------------------------------
% Filenames will be generated with a four-digit prefix to help identify
% order in which data was collected, and to prevent over-writing of old
% files. A dated folder will also be generated and placed in the 'Data'
% folder.

% Base for filename
file_base = ['FrequencySweep_' ...
    device_description '_'...
    num2str(f_start/1e6) 'MHz_to_' ...
    num2str(f_stop/1e6) 'MHz_' ...
    num2str(power) 'dBmDriving_' ...
    date ...
    ];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

% -------------------------------------------------------------------------

% ----------------  Start connection & create headers  --------------------

% Connect to network analyzer and reset to factory settings
net_an = NetworkAnalyzer;
net_an.open;
net_an.reset;

% Set initial values on network analyzer.
net_an.set_start_frequency(f_start);
net_an.set_stop_frequency(f_start + deltaF);
net_an.set_power(power);
net_an.set_S_parameter(1,S_parameter1);
%net_an.set_S_parameter(2,S_parameter2);
net_an.set_n_points(n_points);
net_an.set_trace_type(1,trace1_type);
%net_an.set_trace_type(2,trace2_type);
net_an.set_res_BW(res_BW);
net_an.set_averaging(averaging);
net_an.set_n_aver(n_aver);
net_an.read_parameters;


return;
file_notes = sprintf(['# Measurement of ' device_description '\n'...
    '# Start time:\t' char(datetime('now','Format','yyyy-MMM-dd HH:mm:ss')) '\n' ...
    '# Start frequency:\t%.6f MHz \n'...
    '# Stop frequency:\t%.6f MHz \n' ...
    '# Number of subsweeps:\t%d\n' ...
    '# Power level:\t%f dBm \n' ...
    '# Trace type 1:\t' char(net_an.trace_type(1)) '\n' ...
%    '# Trace type 2:\t' char(net_an.trace_type(2)) '\n' ...
    '# Sweep time:\t%f\n'...
    '# Number of points:\t%d\n'...
    '# Measurement bandwidth:\t%f Hz\n'...
    '# Averaging:\t%d\n'...
    '# N sweeps averaged:\t%d\n'
    ], f_start/1e6, f_stop/1e6, n_subsweeps, power,net_an.sweep_time,net_an.n_points,net_an.res_BW,net_an.averaging,net_an.n_aver);
    
file_headers = sprintf("# Freq[Hz]\tMag[out/M_in]\n");
fprintf(fileID,file_notes);
fprintf(fileID,file_headers);

% -------------------------------------------------------------------------

total_time = 1.01*n_subsweeps*net_an.n_aver*net_an.sweep_time;
hours = floor(total_time/3600);
minutes = floor(total_time/60 - 60*hours);
seconds = floor(total_time - 3600*hours - 60*minutes);
disp(['Time required: ' num2str(hours) ' hours, '...
    num2str(minutes) ' minutes, and '...
    num2str(seconds) ' seconds' ...
    ]);

% Detect key pressed during experiment.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');

% Record data
all_data = [];
net_an.set_power('ON');

for start=f_start:deltaF:(f_stop-deltaF)
    if pressed_key == 27
        break;
    end
    % Set new frequency range
    net_an.set_start_frequency(start);
    net_an.set_stop_frequency(start + deltaF);
    
    % Wait long enough for sweep to complete
    pause(1.01*net_an.n_aver*net_an.sweep_time+1);
    
    % Record new data to file
    data1 = net_an.get_trace(1);
%    data2 = net_an.get_trace(2);
    data = [data1];% data2(:,2)];
    dlmwrite(filename,data,'-append','Delimiter','\t','Precision',10);
    
    all_data = [all_data;data];
    hdl = plot(all_data(:,1)/1e6,all_data(:,2));
    xlabel('Frequency [MHz]');
    ylabel('Signal [out/in]');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
end

print([filename(1:end-3) 'png'],'-dpng');
net_an.set_power('OFF');
net_an.close;
fclose(fileID);

%pause(2);
%close all;
%end
%end
