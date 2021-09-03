clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');



% Operational parameters
freq = 3.066e6; % Sweep start frequency
start_voltage = 0.05; % Driving Vpp
end_voltage = 5;
step_size = 0.05;
sweep_dwell_time = 1.0; % Amount of time to wait for measurement at each point (in seconds)

% File naming parameters
file_base = ['VoltageSweep_I15_noOffset' ...
    num2str(freq/1e6) 'MHz_'...
    num2str(start_voltage) 'to' num2str(end_voltage) 'V_' date];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

file_headers = sprintf("# Voltage[V]\tReal[V]\tImag[V]\tMag[V]\n");
fprintf(fileID,file_headers);








% Create signal generator and lock-in amplifier objects
signal_generator = HP33220A;
lock_in = SR844_LockIn;

% Open connections to instruments
signal_generator.open;
lock_in.open;



% Reset instruments to default settings
signal_generator.reset;

signal_generator.apply_sin(freq,start_voltage,0*start_voltage/2);
pause(5);

% Detect key pressed during experiment.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');

data = [];

for iteration = 1:1
    disp(['Current Iteration:  ' num2str(iteration)]);
    for voltage=[start_voltage:step_size:end_voltage end_voltage:-step_size:start_voltage]
        
        if pressed_key == 27
            break;
        end
        
        % Set signal generator parameters
        signal_generator.apply_sin(freq,voltage,0*voltage/2);
        
        % Wait long enough for data to collect
        pause(sweep_dwell_time);
        
        results = [voltage lock_in.read_real lock_in.read_imaginary lock_in.read_magnitude];
        data = [data; results];
        
        dlmwrite(filename,results,'-append','Delimiter','\t');
        hdl = plot(data(:,1),1000*data(:,2),data(:,1),data(:,3)*1000,data(:,1),data(:,4)*1000);
        legend(hdl,{'Real','Imaginary','Magnitude'},'Location','eastoutside');
        
        xlabel('Driving Voltage [V]');
        ylabel('Signal [mV]');
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    end
end


signal_generator.output_off;
print([filename(1:end-3) 'png'],'-dpng');

signal_generator.close;
fclose('all');