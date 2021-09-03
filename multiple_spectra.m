clear, clc, instrreset;

%--------------------------------------------------------------------------
y_scale = 'LOG'; % Choose y scale (options are 'LIN' or 'LOG')
trace_type = 'AVER'; % Choose trace type ('WRIT', 'AVER', 'MAXH', or 'MINH')

n_points = 40001; % Number of data points
res_BW = 9.1; % Measurement bandwidth in Hz

n_aver = 100;

save_file = true;
folder = 'Data/2017-12-15/';
curr_file_base = 'Piezo1_I15_BlueLightFullPower_9.1HzBW'

%--------------------------------------------------------------------------

spectrum_analyzer = SpectrumAnalyzer; % create object
spectrum_analyzer.open;


for f_start=1e6:1e6:250e6
    
    f_stop = f_start + 1e6;
    
    disp(['Frequencies: ' num2str(f_start/1e6) ' to ' num2str(f_stop/1e6) ' MHz']);
    
    filename = [folder curr_file_base '_' num2str(f_start/1e6) 'MHz.txt'];
    
    
    % Define the command string to be sent to signal generator
    command_string = ['*RST;*CLS;' ...
        ':DISP:WIND:TRAC:Y:SPAC ' y_scale '; '...
        ':SENS:FREQ:STAR ' num2str(f_start) ' HZ; '...
        ':SENS:FREQ:STOP ' num2str(f_stop) ' HZ; '...
        ':SENS:SWE:POIN ' num2str(n_points) ';' ...
        ':SENS:BWID:RES ' num2str(res_BW) ' HZ; '...
        ':TRAC:TYPE ' trace_type ';' ...
        ':INIT:CONT ON;' ...
        ':DISP:WIND:TRAC:Y:RLEV -110 dBm;'
        ];
    
    if trace_type == 'AVER'
        command_string = [command_string ...
            ':SENS:AVER:COUN ' num2str(n_aver) ';' ...
            ];
    end
    fprintf(spectrum_analyzer.handle,command_string)
    
    pause(1);
    sweep_time = spectrum_analyzer.get_sweep_time;
    wait_time = 2*n_aver*sweep_time;
    
    pause(wait_time);
    
    spectrum_analyzer.save_data(filename);
end

fclose(spectrum_analyzer);