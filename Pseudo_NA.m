clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');




% Operational parameters
f_start = 1e6; % Sweep start frequency
f_stop = 85e6; %  Sweep stop frequency
n_points = 10001; % Number of measurement points
set_power = -50; % Driving power in dBm
sweep_dwell_time = 0.05; % Amount of time to wait for measurement at each point (in seconds)
harmonic = 1;


for power = set_power
    instrreset;
    
    % File naming parameters
    file_base = ['FrequencySweep_I15_' ...
        num2str(f_start/1e6) 'to' num2str(f_stop/1e6) 'MHz_'...
        num2str(power) 'dBm_' num2str(harmonic) 'F_Amplified_' date];
    
    % Create new file. Output handle, filename, and folder.
    [fileID,filename,folder] = name_file(file_base);
    
    file_headers = sprintf("# Freq[Hz]\tReal[V]\tImag[V]\tMag[V]\n");
    fprintf(fileID,file_headers);
    
    
    % Create signal generator and lock-in amplifier objects
    signal_generator = SignalGenerator;
    lock_in = SR844_LockIn;
    
    % Open connections to instruments
    signal_generator.open;
    lock_in.open;
    
    
    
    % Reset instruments to default settings
    signal_generator.reset;
    
    
    f_start = f_start/harmonic;
    f_stop = f_stop/harmonic;
    
    df = (f_stop-f_start)/(n_points-1);
    signal_generator.set_frequency(f_start);
    signal_generator.set_power(power);
    lock_in.set_harmonic(harmonic);
    pause(1);
    
    % Detect key pressed during experiment.
    pressed_key = 0;
    h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');
    
    data = [];
    
    for oper_freq=[f_start:df:f_stop]
        
        if pressed_key == 27
            break;
        end
        
        % Set signal generator parameters
        signal_generator.set_frequency(oper_freq);
        signal_generator.set_power(power);
        
        % Wait long enough for data to collect
        pause(sweep_dwell_time);
        
        results = [harmonic*oper_freq lock_in.read_real lock_in.read_imaginary lock_in.read_magnitude];
        data = [data; results];
        
        dlmwrite(filename,results,'-append','Delimiter','\t');
        hdl = plot(data(:,1)/1e6,1000*data(:,2),data(:,1)/1e6,data(:,3)*1000,data(:,1)/1e6,data(:,4)*1000);
        legend(hdl,{'Real','Imaginary','Magnitude'},'Location','eastoutside');
        
        
    end
    
    
    signal_generator.level_off;
    print([filename(1:end-3) 'png'],'-dpng');
    
    signal_generator.close;
    fclose('all');
end