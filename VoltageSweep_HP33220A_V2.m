clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');



% Operational parameters
start_voltage = 0.125; % Low end of power range
end_voltage = 5; % High end of power range
dV = 0.125;
harmonic = 2; % 1=measure at F, 2=measure at 2F


% Create signal generator and lock-in amplifier objects
signal_generator = HP33220A;
lock_in = SR844_LockIn;
spectrum_analyzer = SpectrumAnalyzer;




for lock_in_freq = [15e6]
    for harmonic = [1 2]
        instrreset;
        freq = lock_in_freq / harmonic;
        
        disp(['Current lock-in freq: ' num2str(lock_in_freq/1e6) ' MHz']);
        disp(['Current harmonic: ' num2str(harmonic) 'F']);
        
        % Open connections to instruments
        signal_generator.open;
        lock_in.open;
        spectrum_analyzer.open;
        
        % Reset instruments to default settings
        signal_generator.reset;
        spectrum_analyzer.reset;
        
        signal_generator.apply_sin(freq,end_voltage,0);
        lock_in.set_harmonic(harmonic);
        spectrum_analyzer.set_attenuation(30);
        spectrum_analyzer.set_y_scale('LIN');
        spectrum_analyzer.set_start_frequency(freq-50e3);
        spectrum_analyzer.set_stop_frequency(freq+50e3);
        
        time_const = lock_in.read_time_const;
        sweep_dwell_time = max(10*time_const(2),1);
        
        disp(['Sweep dwell time: ' num2str(sweep_dwell_time) ' seconds']);
        pause(sweep_dwell_time);
        
        max_val = lock_in.read_magnitude;
        curr_sens = lock_in.read_sens;
        
        % Choose the best sensitivity level
        while (max_val < 0.3*curr_sens(2) || max_val > curr_sens(2))
            if (max_val < 0.3*curr_sens(2) && curr_sens(1) > 0)
                lock_in.set_sens(curr_sens(1)-1)
                curr_sens = lock_in.read_sens;
                pause(2*sweep_dwell_time);
                max_val = lock_in.read_magnitude;
            end
            if (max_val >= curr_sens(2) && curr_sens(1) < 14)
                lock_in.set_sens(curr_sens(1)+1)
                curr_sens = lock_in.read_sens;
                pause(2*sweep_dwell_time);
                max_val = lock_in.read_magnitude;
            end
            if (curr_sens(1) == 14 || curr_sens(1)==0)
                break
            end
        end
        
        % File naming parameters
        file_base = ['PowerSweep_I15_' ...
            num2str(freq/1e6) 'MHzDriving_'...
            num2str(start_voltage) 'to' num2str(end_voltage) 'V_' ...
            'MeasureAt' num2str(harmonic) 'F_' ...
            'TimeConst' num2str(time_const(2)) 's_'...
            date];
        
        % Create new file. Output handle, filename, and folder.
        [fileID,filename,folder] = name_file(file_base);
        
        file_headers = sprintf("# DriveSetting[V]\tReal[V]\tImag[V]\tMag[V]\tFreq[Hz]\tDrive@F[V]\tDrive@2F[V]\n");
        fprintf(fileID,file_headers);
        
        
        % Detect key pressed during experiment.
        pressed_key = 0;
        h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');
        
        data = [];
        
        
        for voltage=[start_voltage:dV:end_voltage end_voltage:-dV:start_voltage]
            % Sample uniformly in power
            if pressed_key == 27
                break;
            end
            
            % Set signal generator parameters
            signal_generator.apply_sin(freq,voltage,0);
            spectrum_analyzer.set_start_frequency(freq-50e3);
            spectrum_analyzer.set_stop_frequency(freq+50e3);

            % Wait long enough for data to collect
            if numel(data)==0
                pause(sweep_dwell_time); % Wait longer for first data point
            end
            pause(sweep_dwell_time);
            
            f_voltage = spectrum_analyzer.get_peak_value;
            spectrum_analyzer.set_start_frequency(2*freq-50e3);
            spectrum_analyzer.set_stop_frequency(2*freq+50e3);
            pause(5);
            f2_voltage = spectrum_analyzer.get_peak_value;
            
            results = [voltage lock_in.read_real lock_in.read_imaginary lock_in.read_magnitude lock_in.read_frequency f_voltage f2_voltage];
            data = [data; results];
            
            dlmwrite(filename,results,'-append','Delimiter','\t');
            hdl = plot(data(:,6),1000*data(:,2),'+',data(:,6),data(:,3)*1000,'+',data(:,6),data(:,4)*1000,'+');
            legend(hdl,{'Real','Imaginary','Magnitude'},'Location','eastoutside');
            
            if numel(data == 0)
                line1 = text(0.01,0.98,['Current driving: ' num2str(voltage) ' V'],'Units','Normalized');
            else
                line1.String = ['Current driving: ' num2str(voltage) ' V'];
            end
            
            xlabel('Drive Signal [V]');
            ylabel('Output Signal [mV]');
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
        end
        
        
        signal_generator.output_off;
        print([filename(1:end-3) 'png'],'-dpng');
        
        signal_generator.close;
        lock_in.close;
        spectrum_analyzer.close;
        fclose('all');

        if pressed_key == 27
                break;
        end
    end
    
    if pressed_key == 27
        break;
    end
end
disp('Done.');