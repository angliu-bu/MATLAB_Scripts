clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');




% Operational parameters
f_start = 1e6; % Sweep start frequency
f_stop = 200e6; %  Sweep stop frequency
sweep_dwell_time = 0.1; % Amount of time to wait for measurement at each point (in seconds)
harmonic = 1;

for harmonic = [1]
    instrreset;
    % File naming parameters
    file_base = ['FrequencySweep_LockInWithLoad_' ...
        num2str(f_start/1e6) 'to' num2str(f_stop/1e6) 'MHz_'...
        num2str(harmonic) 'F_Amplified-false_0dBattenuation_' date];
    
    % Create new file. Output handle, filename, and folder.
    [fileID,filename,folder] = name_file(file_base);
    
    file_headers = sprintf("# DriveFreq[Hz]\tMeasFreq[Hz]\tReal[V]\tImag[V]\tMag[V]\n");
    fprintf(fileID,file_headers);
    
    lock_in = SR844_LockIn;
    lock_in.open;
    
    lock_in.set_harmonic(harmonic);
    pause(1);
    
    % Detect key pressed during experiment.
    pressed_key = 0;
    h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');
    
    data = [];
    
    for meas_freq=[1e6:0.01e6:10e6 10.1e6:0.1e6:100e6 101e6:1e6:200e6]
        
        if pressed_key == 27
            break;
        end
        
        % Set freq
        lock_in.set_frequency(meas_freq, true);
        
        % Wait lock and settling enough for data to collect
        fprintf(lock_in.handle,"LIAS?;");
        while str2num(fscanf(lock_in.handle)) > 0
            pause(0.05);
            fprintf(lock_in.handle,"LIAS?;");
        end
        pause(sweep_dwell_time);
        
        results = [meas_freq/harmonic meas_freq lock_in.read_real lock_in.read_imaginary lock_in.read_magnitude];
        data = [data; results];
        
        dlmwrite(filename,results,'-append','Delimiter','\t');
        hdl = plot(data(:,2)/1e6,1000*data(:,3),data(:,2)/1e6,data(:,4)*1000,data(:,2)/1e6,data(:,5)*1000);
        legend(hdl,{'Real','Imaginary','Magnitude'},'Location','eastoutside');
        
        if numel(data == 0)
            line1 = text(0.01,0.98,['Current frequency: ' num2str(meas_freq/1e6) ' MHz'],'Units','Normalized');
        else
            line1.String = ['Current frequency: ' num2str(meas_freq/1e6) ' MHz'];
        end
        
        
        xlabel('Measurement Frequency [MHz]');
        ylabel('Signal [mV]');
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    end
    
    print([filename(1:end-3) 'png'],'-dpng');
    
    fclose('all');
end