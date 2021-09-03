clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');



file_base = 'SidebandSize_15.168MHzMode_AcousticFrequencySweep_A0.1_1HzBW';
[fileID,filename,folder] = name_file(file_base);


file_headers = sprintf('#Freq[Hz]\tSideband [V]');

% Sound wave properties
A = 0.1; % Sound amplitude
Fs = 192000; % Sampling frequency of speaker
freq = 200; % Sound frequency in Hz
f0=15168000;

% Signal Generator Properties
power = 19;

% Spectrum analyzer Properties
span = 10;  % Frequency span of analyzer in Hz
res_BW = 1; % BW in Hz
n_aver = 10; % Number of points to average over



% Open connection to spectrum analyzer
spectrum_analyzer = SpectrumAnalyzer;
signal_generator = SignalGenerator;

spectrum_analyzer.open;
signal_generator.open;


% Reset instruments to default settings
signal_generator.reset;
spectrum_analyzer.reset;

fprintf(fileID,[file_headers '\n']); % Write headers to file
disp(file_headers); % Display headers in terminal



all_results = [];



for freq=200
    f_start = f0 + freq - span/2; % Start frequency
    f_stop = f0 + freq + span/2; % Stop frequency

    
    % Set signal generator
    signal_generator.set_frequency(f0);
    signal_generator.set_power(power);
    
    % Set spectrum analyzer
    spectrum_analyzer.reset;
    spectrum_analyzer.set_start_frequency(f_start);
    spectrum_analyzer.set_stop_frequency(f_stop);
    spectrum_analyzer.set_res_BW(res_BW);
    spectrum_analyzer.set_y_scale('LIN');
    spectrum_analyzer.set_ref_level(-40);
    spectrum_analyzer.set_trace_type('AVER');
    spectrum_analyzer.set_n_aver(n_aver);
    spectrum_analyzer.set_attenuation(20);
    spectrum_analyzer.restart;
    
    sweep_time = spectrum_analyzer.get_sweep_time;
    
    % Create sound
    T = 2.1*n_aver*sweep_time + 5.0; % Time length of sound
    tone = create_tone(freq,A,T);   % API for creating tone
    
    pause(0.99*T); % Wait for 99% of length of tone
    
    % Move marker to largest peak and measure it
    results = spectrum_analyzer.get_peak_value; % Read voltage at marker
    
    all_results = [all_results;freq results];
    result_string = sprintf('%0.10f\t%0.9f',all_results(end,1),all_results(end,2)); % Define results string
    disp(result_string); % Write results to terminal
    fprintf(fileID,[result_string '\n']); % Write results to file
    stop(tone); % Stop playing tone
    
    
    scatter(all_results(:,1),all_results(:,2));
end


signal_generator.level_off;
signal_generator.close;
spectrum_analyzer.close;
fclose(fileID); % Close data file
disp('Done.'); % Inform user that script has finished.
