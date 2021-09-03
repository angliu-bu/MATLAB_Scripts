clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');



% Operational parameters
freq = 3.15e6; % Sweep start frequency
start_voltage = 0.224; % Low end of voltage range
end_voltage = 1; % High end of voltage range
sweep_dwell_time = 3; % Amount of time to wait for measurement at each point (in seconds)
n_points = 100;
harmonic = 2; % 1=measure at F, 2=measure at 2F


% Create signal generator and lock-in amplifier objects
signal_generator = SignalGenerator;
lock_in = SR844_LockIn;





for lock_in_freq = [0.5e6:0.5e6:1.5e6]
    for harmonic = [1 2]
        instrreset;
        freq = lock_in_freq / harmonic;
        
        disp(['Current lock-in freq: ' num2str(lock_in_freq/1e6) ' MHz']);
        disp(['Current harmonic: ' num2str(harmonic) 'F']);
        
        % Open connections to instruments
        signal_generator.open;
        lock_in.open;
        
        % Reset instruments to default settings
        signal_generator.reset;
        
        signal_generator.set_frequency(freq);
        end_power = round(10*log10(end_voltage^2/0.05),1,'decimals');
        signal_generator.set_power(end_power);
        lock_in.set_harmonic(harmonic);
        
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
            'MeasureAt' num2str(harmonic) 'F_' date];
        
        % Create new file. Output handle, filename, and folder.
        [fileID,filename,folder] = name_file(file_base);
        
        file_headers = sprintf("# Power[dBm]\tReal[V]\tImag[V]\tMag[V]\n");
        fprintf(fileID,file_headers);
        
        
        % Detect key pressed during experiment.
        pressed_key = 0;
        h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');
        
        data = [];
        
        
        for i=1:n_points
            % Sample uniformly in voltage
            power = round(10*log10(((end_voltage - start_voltage)*rand()+start_voltage)^2/0.05),1,'decimals');
            if pressed_key == 27
                break;
            end
            
            % Set signal generator parameters
            signal_generator.set_power(power);
            
            % Wait long enough for data to collect
            pause(sweep_dwell_time);
            
            results = [power lock_in.read_real lock_in.read_imaginary lock_in.read_magnitude];
            data = [data; results];
            
            dlmwrite(filename,results,'-append','Delimiter','\t');
            hdl = plot(data(:,1),1000*data(:,2),'+',data(:,1),data(:,3)*1000,'+',data(:,1),data(:,4)*1000,'+');
            legend(hdl,{'Real','Imaginary','Magnitude'},'Location','eastoutside');
            
            if numel(data == 0)
                line1 = text(0.01,0.98,['Current Point: ' num2str(i)],'Units','Normalized');
                line2 = text(0.01,0.96,['Current Power: ' num2str(power) ' dBm'],'Units','Normalized');
            else
                line1.String = ['Current Iteration: ' num2str(iteration)];
                line2.String = ['Current Power: ' num2str(power) ' dBm'];
            end
            
            xlabel('Power [dBm]');
            ylabel('Signal [mV]');
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
        end
        
        
        signal_generator.level_off;
        print([filename(1:end-3) 'png'],'-dpng');
        
        signal_generator.close;
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