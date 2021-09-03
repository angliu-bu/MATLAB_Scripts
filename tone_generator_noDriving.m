clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');

% Open connection to spectrum analyzer
spectrum_analyzer = SpectrumAnalyzer;

spectrum_analyzer.open;
fileID = fopen('Data/2017-07-07/SidebandSize_15.168MHzMode_AcousticPowerSweep_freq200Hz_1HzBW_Random_1.txt','w'); % Open data file to write to


% Reset instruments to default settings
spectrum_analyzer.reset;

% Sound wave properties
A = 1; % Sound amplitude
Fs = 192000; % Sampling frequency of speaker
freq = 200; % Sound frequency in Hz


% Spectrum analyzer Properties
res_BW = 1; % BW in Hz
n_aver = 10; % Number of points to average over
f_start = 5; % Start frequency
f_stop = 2*freq; % Stop frequency

A = rand;

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

% Create sound object
T = 2.1*n_aver*sweep_time + 5.0; % Time length of sound
t = 0:1/Fs:T;               % Create tone time series
y = A*sin(2*pi*freq*t);     % Generate tone signal
tone = audioplayer(y,Fs);   % API for creating tone

disp(['Wait time: ' num2str(T) ' seconds']);

play(tone); % Start playing tone
pause(0.99*T); % Wait for 99% of length of tone
stop(tone); % Stop playing tone

spectrum_analyzer.save_data('test.txt');


spectrum_analyzer.close;

disp('Done.'); % Inform user that script has finished.
