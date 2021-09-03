clear, clc, instrreset;

%--------------------------------------------------------------------------
freq = 15168000; %Frequency in Hz
level = 10; % Signal size in dBm

sweep = true; % Define sweep on or off
f_start = 14500000; % Sweep start frequency in Hz
f_stop = 16000000; % Sweep stop frequency in Hz
step = 1000; % Sweep frequency step in Hz
dwell = 15; % Frequency dwell time in ms

%--------------------------------------------------------------------------


sig_gen = visa('ni','GPIB0::28::1::INSTR'); % Define signal generator handle
fopen(sig_gen); % Open connection to signal generator

fprintf(sig_gen,':LEVEL OFF; '); % Turn off while modifying parameters

% Define the command string to be sent to signal generator
command_string = ['*RST;*CLS;LEVEL ' num2str(level) '; '];

if sweep
    command_string = [command_string ...
        'RF:STA ' num2str(f_start) ' HZ; ' ...
        'RF:STO ' num2str(f_stop) ' HZ; ' ...
        'RF:STE ' num2str(step) ' HZ; ' ...
        'TIME ' num2str(dwell) ' MS; ' ...
        'SWP:R; '...
        'SWP ON; ' ...
        ];
else
    command_string = [command_string ...
        'RF ' num2str(freq) ' HZ; '];
end

command_string = [command_string 'LEVEL ON; '];

fprintf(sig_gen,command_string)

fclose(sig_gen);