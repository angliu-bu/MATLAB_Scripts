clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');
folder = sprintf('Data/%4.0f-%02.0f-%02.0f',year(date),month(date),day(date));
file_base = 'FrequencySweep_15.1MHzMode_';

% Operational parameters
f_start = 14500000; % Sweep start frequency
f_stop = 16000000; % Sweep stop frequency
res_BW = 9100; % measurement bandwidth
n_points = 1001; % Number of measurement points

power = 19;


% Create signal generator and spectrum analyzer objects
signal_generator = SignalGenerator;
spectrum_analyzer = SpectrumAnalyzer;

% Open connections to instruments
signal_generator.open;
spectrum_analyzer.open;


for power = 19:-3:-20
    
    % -------------------- Set Upsweep Parameters ---------------
    
    disp(['Current power: ' num2str(power) ' dBm -- Upsweep']);
    
    % Reset instruments to default settings
    signal_generator.reset;
    spectrum_analyzer.reset;
    
    % Set spectrum analyzer parameters
    spectrum_analyzer.set_start_frequency(f_start);
    spectrum_analyzer.set_stop_frequency(f_stop);
    spectrum_analyzer.set_res_BW(res_BW);
    spectrum_analyzer.set_n_points(n_points);
    spectrum_analyzer.set_y_scale('LIN');
    spectrum_analyzer.set_trace_type('MAXH');
    spectrum_analyzer.set_ref_level(10);
    
    % Set signal generator parameters
    signal_generator.set_start_frequency(f_start);
    signal_generator.set_stop_frequency(f_stop);
    signal_generator.set_power(power);
    signal_generator.set_step_size((f_stop-f_start)/(n_points-1));
    
    pause(1);
    
    % Measure time requred for a sweep
    sweep_dwell_time = spectrum_analyzer.get_sweep_time;
    
    % Set signal generator dwell time to longer than sweep time
    signal_generator.set_dwell_time(2*sweep_dwell_time);
    
    % Start sweep
    signal_generator.sweep_on;
    
    % Wait long enough for data to collect
    wait_time = 2*1.1*n_points*sweep_dwell_time
    pause(wait_time);
    
    % Save data to file
    filename = [folder '/' file_base num2str(power) 'dBm_Upsweep.txt'];
    spectrum_analyzer.save_data(filename);
    
    % Show graph of data collected
    spectrum_analyzer.display_data;
    
    
    
    
    % -------------------- Set Downsweep Parameters ---------------
    
    disp(['Current power: ' num2str(power) ' dBm -- Downsweep']);
    
    % Reset instruments to default settings
    signal_generator.reset;
    spectrum_analyzer.reset;
    
    % Set spectrum analyzer parameters
    spectrum_analyzer.set_start_frequency(f_start);
    spectrum_analyzer.set_stop_frequency(f_stop);
    spectrum_analyzer.set_res_BW(res_BW);
    spectrum_analyzer.set_n_points(n_points);
    spectrum_analyzer.set_y_scale('LIN');
    spectrum_analyzer.set_trace_type('MAXH');
    spectrum_analyzer.set_ref_level(10);
    
    % Set signal generator parameters
    signal_generator.set_start_frequency(f_stop);
    signal_generator.set_stop_frequency(f_start);
    signal_generator.set_power(power);
    signal_generator.set_step_size((f_stop-f_start)/(n_points-1));
    
    pause(1);
    
    % Measure time requred for a sweep
    sweep_dwell_time = spectrum_analyzer.get_sweep_time;
    
    % Set signal generator dwell time to longer than sweep time
    signal_generator.set_dwell_time(2*sweep_dwell_time);
    
    % Start sweep
    signal_generator.sweep_on;
    
    % Wait long enough for data to collect
    wait_time = 2*1.1*n_points*sweep_dwell_time
    pause(wait_time);
    
    % Save data to file
    filename = [folder '/' file_base num2str(power) 'dBm_Downsweep.txt'];
    spectrum_analyzer.save_data(filename);
    
    % Show graph of data collected
    spectrum_analyzer.display_data;
end

signal_generator.level_off;


signal_generator.close;
spectrum_analyzer.close;
fclose('all');
