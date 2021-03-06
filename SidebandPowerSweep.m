clear, clc, instrreset;


device_description = 'Piezo1_C06_Vacuum';

% Signal Generator parameters
sig_gen_freq = 63.556e6; % Frequency in Hz
sig_gen_power = 19.0; % power in dBm


% Waveform generator parameters
waveform_freq = 100; % frequency in Hz
waveform_Vpp_start = 0.01; % starting vpp for waveform generator (min power)
waveform_Vpp_stop = 0.34; % stop vpp (max power)
power_step_size = 0.03;

% Spectrum analyzer parameters
freq_span = 25;

SA_BW = 1; % Spectrum analyzer bandwidth in Hz
SA_ref_level = -76; % SA reference level in V.
SA_n_aver = 10;

% --------------- Set up signal generator -------------------------
sig_gen = SignalGenerator;
sig_gen.open;
sig_gen.set_frequency(sig_gen_freq);
sig_gen.set_power(sig_gen_power);
sig_gen.level_on;


% --------------- Set up spectrum analyzer -------------------------
SA = SpectrumAnalyzer;
SA.open;
SA.reset;

SA.set_res_BW(SA_BW);

SA.set_ref_level(SA_ref_level);
SA.set_y_scale('LIN');
SA.set_trace_type('AVER');
SA.set_n_aver(SA_n_aver);

% --------------- Set up waveform generator -------------------------
WG = HP33220A;
WG.open;



for waveform_freq = [100 200 400 500 750 1000]

 % Find actual driving frequency first
SA_f_start = sig_gen_freq - 500;
SA_f_stop = sig_gen_freq + 500;
SA.set_start_frequency(SA_f_start);
SA.set_stop_frequency(SA_f_stop);

pause(2*SA.get_sweep_time)
sig_gen_freq = SA.get_peak_freq;
    
    
SA_f_start = sig_gen_freq - waveform_freq - freq_span/2;
SA_f_stop = sig_gen_freq - waveform_freq + freq_span/2;
SA.set_start_frequency(SA_f_start);
SA.set_stop_frequency(SA_f_stop);
% ---------------------------  File naming  -------------------------------
% Filenames will be generated with a four-digit prefix to help identify
% order in which data was collected, and to prevent over-writing of old
% files. A dated folder will also be generated and placed in the 'Data'
% folder.

% Base for filename
file_base = ['SidebandPowerSweep_' ...
    device_description '_'...
    num2str(waveform_Vpp_start) 'V_to_' ...
    num2str(waveform_Vpp_stop) 'V_' ...
    num2str(sig_gen_power) 'dBmDriving_' ...
    num2str(sig_gen_freq/1e6) 'MHzDriving_' ...
    num2str(waveform_freq) 'HzModulation_' ...
    date ...
    ];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

file_notes = sprintf(['# Measurement of ' device_description '\n'...
    '# Start time:\t' char(datetime('now','Format','yyyy-MMM-dd HH:mm:ss')) '\n' ...
    '# Drive frequency:\t%.6f MHz \n'...
    '# Modulation frequency:\t%.6f Hz \n' ...
    '# Power level:\t%f dBm \n' ...
    '# Measurement bandwidth:\t%f Hz\n'...
    '# N sweeps averaged:\t%d\n'
    ], sig_gen_freq/1e6, waveform_freq, sig_gen_power,SA_BW,SA.n_aver);
    
file_headers = sprintf("# WaveformAmp[V]\tPeakValue[V]\n");
fprintf(fileID,file_notes);
fprintf(fileID,file_headers);


data = [];
for wg_voltage = [waveform_Vpp_start:power_step_size:waveform_Vpp_stop]
    SA.restart;
    WG.apply_sin(waveform_freq,wg_voltage,0);
    pause(1.1*SA.n_aver*SA.get_sweep_time);
    %SA.display_data(false);
    new_data = [wg_voltage SA.get_peak_value];
    dlmwrite(filename,new_data,'-append','Delimiter','\t','Precision',10);
    data = [data; new_data];
    hdl = plot(data(:,1)*1000,data(:,2)*1e6,'+');
    xlabel('Waveform Amplitude [mV]');
    ylabel('Sideband Size [uV]');
end
print([filename(1:end-3) 'png'],'-dpng');


end
%sig_gen.level_off;
sig_gen.close;
SA.close;
WG.close;
fclose('all');
