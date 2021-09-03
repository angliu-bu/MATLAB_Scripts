clear, clc, instrreset;

%--------------------------------------------------------------------------
f_start = 14500000; % Sweep start frequency in Hz
f_stop = 16000000; % Sweep stop frequency in Hz

y_scale = 'LIN'; % Choose y scale (options are 'LIN' or 'LOG')
trace_type = 'AVER'; % Choose trace type ('WRIT', 'AVER', 'MAXH', or 'MINH')

n_points = 40001; % Number of data points
res_BW = 1; % Measurement bandwidth in Hz

n_aver = 100;

save_file = true;
filename = 'Data/Piezo1_I15_15.168MHz_10dBm_9100HzBW.txt';
%--------------------------------------------------------------------------

spectrum_analyzer = visa('ni','GPIB0::18::1::INSTR'); % Define signal generator handle
spectrum_analyzer.InputBufferSize = 16*n_points;
fopen(spectrum_analyzer); % Open connection to signal generator

% Define the command string to be sent to signal generator
command_string = ['*RST;*CLS;' ...
    ':DISP:WIND:TRAC:Y:SPAC ' y_scale '; '...
    ':SENS:FREQ:STAR ' num2str(f_start) ' HZ; '...
    ':SENS:FREQ:STOP ' num2str(f_stop) ' HZ; '...
    ':SENS:SWE:POIN ' num2str(n_points) ';' ...
    ':SENS:BWID:RES ' num2str(res_BW) ' HZ; '...
    ':TRAC:TYPE ' trace_type ';' ...
    ':INIT:CONT ON;' ...
    ':DISP:WIND:TRAC:Y:RLEV 10 dBm;'
    ];

if trace_type == 'AVER'
    command_string = [command_string ...
        ':SENS:AVER:COUN ' num2str(n_aver) ';' ...
        ];
end
fprintf(spectrum_analyzer,command_string)

pause(1);
fprintf(spectrum_analyzer,':SENS:SWE:TIME?;');
sweep_time = str2double(fscanf(spectrum_analyzer));
wait_time = 1.1*sweep_time*n_points + 5.0
pause(wait_time);

fprintf(spectrum_analyzer,':TRAC:DATA? TRACE1;');
data = str2num(fscanf(spectrum_analyzer));
freqs = [f_start:(f_stop-f_start)/(n_points-1):f_stop];
plot(freqs,data)
fclose(spectrum_analyzer);


if save_file
    spectrum_analyzer.save_file(filename);
end