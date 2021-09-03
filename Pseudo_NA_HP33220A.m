clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');



% Operational parameters
start_freq = 3.025e6; % Sweep start frequency
stop_freq = 3.075e6;
voltage = 0.05; % Driving Vpp
n_steps = 101;
step_size = (stop_freq - start_freq)/(n_steps-1);
sweep_dwell_time = 1; % Amount of time to wait for measurement at each point (in seconds)

% File naming parameters
file_base = ['FrequencySweep_I15_' ...
    num2str(start_freq/1e6) 'to' num2str(stop_freq/1e6) 'MHz_'...
    num2str(voltage) 'V_' date];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

file_headers = sprintf("# Freq[Hz]\tReal[V]\tImag[V]\tMag[V]\n");
fprintf(fileID,file_headers);








% Create signal generator and lock-in amplifier objects
signal_generator = HP33220A;
lock_in = SR844_LockIn;

% Open connections to instruments
signal_generator.open;
lock_in.open;



% Reset instruments to default settings
signal_generator.reset;

signal_generator.apply_sin(start_freq,voltage,0);
pause(5);

% Detect key pressed during experiment.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');

data = [];

for iteration = 1:1
    disp(['Current Iteration:  ' num2str(iteration)]);
    for freq=[start_freq:step_size:stop_freq]
        
        if pressed_key == 27
            break;
        end
        
        % Set signal generator parameters
        signal_generator.apply_sin(freq,voltage,0);
        
        % Wait long enough for data to collect
        pause(sweep_dwell_time);
        
        results = [freq lock_in.read_real lock_in.read_imaginary lock_in.read_magnitude];
        data = [data; results];
        
        dlmwrite(filename,results,'-append','Delimiter','\t');
        hdl = plot(data(:,1)/1e6,1000*data(:,2),data(:,1)/1e6,data(:,3)*1000,data(:,1)/1e6,data(:,4)*1000);
        legend(hdl,{'Real','Imaginary','Magnitude'},'Location','eastoutside');
        
        xlabel('Driving Frequency [MHz]');
        ylabel('Signal [mV]');
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    end
end


signal_generator.output_off;
print([filename(1:end-3) 'png'],'-dpng');

signal_generator.close;
fclose('all');