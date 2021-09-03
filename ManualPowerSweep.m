clear, clc, instrreset;

frequency = 120e6;

lock_in = SR844_LockIn;
lock_in.open;


lock_in.set_frequency(frequency, false);

data = [];

% File naming parameters
file_base = ['ManualPowerSweep_I15_' ...
    num2str(frequency/1e6) 'MHzMeasurement_'...
    date
    ];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);
headers = ['# Drive voltages are attenuated 50 dB extra for measurements \n'...
    '# Atten[dB]\tAmp?\tD1M1_inputR[V]\tD1M1_inputI[V]\tD1M1_inputM[V]\tD.5M.5_inputR[V]\tD.5M.5_inputI[V]\tD.5M.5_inputM[V]\tD.5M1_inputR[V]\tD.5M1_inputI[V]\tD.5M1_inputM[V]\tD1M1_outputR[V]\tD1M1_outputI[V]\tD1M1_outputM[V]\tD.5M1_outputR[V]\tD.5M1_outputI[V]\tD.5M1_outputM[V] \n' ...
    ];
fprintf(fileID,headers);


while true
    lock_in.set_harmonic(1);
    
    prompt = {'Sum of all attenuator values [dB]:', 'Amplifier?'};
    dims = [1 35];
    answer = [];
    answer = inputdlg(prompt,"Input Signal",dims);
    if numel(answer) < 2
        break;
    end
    fprintf(fileID,'%s\t%s\t',char(answer(1)),char(answer(2)));
    
    % Next: measure time constant, measure real, imaginary, magnitude.
    time_const = lock_in.read_time_const;
    dwell_time = 20*time_const(2);
    pause(dwell_time);
    fprintf(fileID,'%.12f\t%.12f\t%.12f\t',lock_in.read_real,lock_in.read_imaginary,lock_in.read_magnitude);
    
    % Switch to frequency/2, harmonic 1, measure again.
    lock_in.set_frequency(frequency/2,false)
    pause(dwell_time);
    fprintf(fileID,'%.12f\t%.12f\t%.12f\t',lock_in.read_real,lock_in.read_imaginary,lock_in.read_magnitude);
    
    % Switch to frequency, harmonic 2, measure again.
    lock_in.set_frequency(frequency,false);
    lock_in.set_harmonic(2);
    pause(dwell_time);
    fprintf(fileID,'%.12f\t%.12f\t%.12f\t',lock_in.read_real,lock_in.read_imaginary,lock_in.read_magnitude);
    
    
    % Switch to frequency, harmonic 1, DO NOT MEASURE
    lock_in.set_harmonic(1);
    
    % Prompt to change wiring
    inputdlg("Turn off amplifier (if applicable) and switch to wire 4. Then, turn amplifier back on");
    
    % Measure real, imaginary, magnitude
    pause(dwell_time);
    fprintf(fileID,'%.12f\t%.12f\t%.12f\t',lock_in.read_real,lock_in.read_imaginary,lock_in.read_magnitude);
    
    % Switch to harmonic 2, measure again.
    lock_in.set_harmonic(2);
    pause(dwell_time);
    fprintf(fileID,'%.12f\t%.12f\t%.12f\t',lock_in.read_real,lock_in.read_imaginary,lock_in.read_magnitude);
    
    % Prompt to change wiring
    inputdlg("Turn off amplifier (if applicable). and switch to wire 3. Then, turn amplifier back on");
    fprintf(fileID,'\n');
end

lock_in.close;
fclose('all');

        