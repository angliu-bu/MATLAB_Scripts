clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');

% Sound wave properties
A = 0.1; % Sound amplitude
Fs = 192000; % Sampling frequency of speaker
freq = 200; % Sound frequency in Hz

% Spectrum analyzer Properties
span = 10;  % Frequency span of analyzer in Hz
res_BW = 1; % BW in Hz
n_aver = 10; % Number of points to average over



% Open connection to spectrum analyzer
spectrum_analyzer = SpectrumAnalyzer;
spectrum_analyzer.open;


% Reset instruments to default settings
spectrum_analyzer.reset;


hold on;

for A = 0:0.05:1
    file_base = sprintf('SidebandSize_DirectAcousticActuation_1HzBW_%dHz_A%.2f',freq,A);
    [fileID,filename,folder] = name_file(file_base);
    fclose(fileID);
    
    f_start = 0.5*freq; % Start frequency
    f_stop = 1.5*freq; % Stop frequency

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
    
    spectrum_analyzer.save_data(filename);
    spectrum_analyzer.display_data(false);
    
    
    stop(tone); % Stop playing tone

end

spectrum_analyzer.close;
disp('Done.'); % Inform user that script has finished.
