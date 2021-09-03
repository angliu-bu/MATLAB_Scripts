clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');



% Operational parameters
freq = 3.0679e6; % Sweep start frequency
start_power = -30; % Driving power in dBm
end_power = 19;
step_size = 0.2;
sweep_dwell_time = 1; % Amount of time to wait for measurement at each point (in seconds)

% File naming parameters
file_base = ['PowerSweep_I15_' ...
    num2str(freq/1e6) 'MHz_'...
    num2str(start_power) 'to' num2str(end_power) 'dBm_' date];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

file_headers = sprintf("# Power[dBm]\tPhase[deg]\n");
fprintf(fileID,file_headers);


% Create signal generator and lock-in amplifier objects
signal_generator = SignalGenerator;
lock_in = SR844_LockIn;

% Open connections to instruments
signal_generator.open;
lock_in.open;



% Reset instruments to default settings
signal_generator.reset;

signal_generator.set_frequency(freq);
signal_generator.set_power(start_power);
pause(5);

% Detect key pressed during experiment.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');

data = [];

for iteration = 1:10
    disp(['Current Iteration:  ' num2str(iteration)]);
    for power=[start_power:step_size:end_power end_power:-step_size:start_power]
        
        if pressed_key == 27
            break;
        end
        
        % Set signal generator parameters
        signal_generator.set_frequency(freq);
        signal_generator.set_power(power);
        
        % Wait long enough for data to collect
        pause(sweep_dwell_time);
        
        real_part = lock_in.read_real;
        imag_part = lock_in.read_imaginary;
        magn = lock_in.read_magnitude;
        results = [power lock_in.read_phase 180./pi*atan(imag_part/real_part/magn)];
        data = [data; results];
        
        dlmwrite(filename,results,'-append','Delimiter','\t');
        hdl = plot(data(:,1),data(:,2),data(:,1),data(:,3));
        legend(hdl,{'Phase','Pseudo-phase'});
        
        xlabel('Power [dBm]');
        ylabel('Phase [deg]');
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    end
end


signal_generator.level_off;
print([filename(1:end-3) 'png'],'-dpng');

signal_generator.close;
fclose('all');

disp('Done.');