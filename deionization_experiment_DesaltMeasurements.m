clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');


% --------------- Data recording parameters -------------------------------

sensor_freq = 200e3; % Frequency of salt sensors in Hz

pump_rate = 10; % Syringe pump flow rate in uL/min
v_max = -500; % Max pump volume in uL
pre_charge = 50; % Fluid to flow through channel before turning on DI electrodes

% Data to write to file
time_on = true; % Record time -- this shoud always be on
S1_on = true; % Output 0 of multiplexer
S2_on = true; % Output 1 of multiplexer
S1S2_on = true; % Output 2 of multiplexer
pump_rate_on = true; % Write pump rate to file
lock_in_freq_on = true; % Write lock-in amplifier frequency to file
DI_voltage_on = true; % Write DI voltage to file


file_base = ['ConductivityTest_' date '_10mM_Desalt_' num2str(pump_rate) 'upm'];


initial_notes = ...
    ['# Concentration:\t10 mM \n' ...
    '# Syringe size:\t10 mL \n' ...
    '# Resistor value:\t301-ohm \n' ...
    '# Pre-charge: ' num2str(pre_charge) ' uL\n' ...
    '# Bottom electrode grounded \n' ...
    ];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

header_toggle = [time_on ...
    S1_on ...
    S1_on ...
    S1_on ...
    S2_on ...
    S2_on ...
    S2_on ...
    S1S2_on ...
    S1S2_on ...
    S1S2_on ...
    pump_rate_on ...
    lock_in_freq_on ...
    DI_voltage_on ...
    ];

all_headers = ["Time[s]" ...
    "S1_Real[V]" ...
    "S1_Imag[V]" ...
    "S1_Mag[V]" ...
    "S2_Real[V]" ...
    "S2_Imag[V]" ...
    "S2_Mag[V]" ...
    "S1S2_Real[V]" ...
    "S1S2_Imag[V]" ...
    "S1S2_Mag[V]" ...
    "Rate[uL/min]" ...
    "Frequency[Hz]" ...
    "DI_volt[V]" ...
    ];

file_headers = "#";
for i=1:numel(all_headers);
    if header_toggle(i)
        file_headers = sprintf('%s\t%s',file_headers,all_headers(i));
    end
end
file_headers = sprintf('%s\n',file_headers);


% --------------- Define and connect to all equipment ---------------------
lock_in = SR844_LockIn;
multimeter = HP3478A_Multimeter;
pump = ChemyxSyringePump;
sig_gen = SignalGenerator;
sensorSwitch = arduino;
waveform_gen = HP33220A;

lock_in.open;
multimeter.open;
pump.open;
sig_gen.open;
waveform_gen.open;

% -------------------------------------------------------------------------


% --------------- Set signal generator parameters -------------------------

sig_gen.set_frequency(sensor_freq);
sig_gen.set_power(13.0);

% -------------------------------------------------------------------------


% ---------------- Set arduino to sensor 1 --------------------------------

writeDigitalPin(sensorSwitch,'D2',0);
writeDigitalPin(sensorSwitch,'D3',0);
delay_time = 0.025; % delay before measurement.

% -------------------------------------------------------------------------




% ----------------- Set Syringe pump parameters ---------------------------

pump.set_units(2);
pump.set_volume(v_max);
pump.set_rate(pump_rate);

% -------------------------------------------------------------------------



% ---------------- Publish operation parameters in head of file -----------

fprintf(fileID, initial_notes);

fprintf(fileID,'# Sensor Frequency:\t%f kHz\n',sensor_freq/1000);
fprintf(fileID,'# Flow rate:\t%f uL/min\n',pump_rate);
fprintf(fileID,'# Sensor 1 State:\t%d\n',S1_on);
fprintf(fileID,'# Sensor 2 State:\t%d\n',S2_on);
fprintf(fileID,'# S1-S2 State:\t%d\n',S1S2_on);

fprintf(fileID, file_headers);

% -------------------------------------------------------------------------


% -------------------------- Initialize parameters ------------------------

% Record start time of experiment
start_time = now*86400;
time = 0;

% Create data matrix for plotting
data = [];

% Detect key pressed during experiment.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');


pump.start;
pause(0.5);

% -------------------------------------------------------------------------

% Loop continues until 'Esc' key is pressed or pump volume is achieved.
while pressed_key ~= 27 && time < abs(60*v_max/pump_rate)
    
    prev_time = time;
    % Record desired results
    time = 86400*now - start_time;
    results = [time];
    
    if (time/60.0*pump_rate > pre_charge) && (prev_time/60.0*pump_rate <= pre_charge) && DI_voltage_on
        waveform_gen.apply_square(1/480.0, 1.4, 0);
    end
    
    % Switch to sensor 1
    if S1_on
        writeDigitalPin(sensorSwitch,'D2',0);
        writeDigitalPin(sensorSwitch,'D3',0);
        pause(delay_time);
        
        % Add sensor 1 data to results
        results = [results ...
            lock_in.read_real ...
            lock_in.read_imaginary ...
            lock_in.read_magnitude ...
            ];
    end

    % Switch to sensor 2
    if S2_on
        writeDigitalPin(sensorSwitch,'D2',1);
        writeDigitalPin(sensorSwitch,'D3',0);
        pause(delay_time);

        % Add sensor 2 data to results
        results = [results ...
            lock_in.read_real ...
            lock_in.read_imaginary ...
            lock_in.read_magnitude ...
            ];
    end

    % Switch to S1-S2
    if S1S2_on
        writeDigitalPin(sensorSwitch,'D2',0);
        writeDigitalPin(sensorSwitch,'D3',1);
        pause(delay_time);
        
        % Add differential data to results
        results = [results ...
            lock_in.read_real ...
            lock_in.read_imaginary ...
            lock_in.read_magnitude ...
            ];
    end
    
    % Add operation parameters to results
    if pump_rate_on
        results = [results pump.rate];
    end
    
    if lock_in_freq_on
        results = [results lock_in.read_frequency];
    end
    
    if DI_voltage_on
        results = [results multimeter.measure];
    end
    
    % Write all results to file.
    dlmwrite(filename,results,'-append','Delimiter','\t');
    
    % Append latest results to data matrix
    data = [data; results];

    hdl = plot(data(:,1),data(:,5));
    legend('S2 Real','Location','southoutside');
    
%     hdl = plot(data(:,1),data(:,2),'--b', data(:,1),data(:,3),':b',data(:,1),data(:,4),'b',...
%        data(:,1),data(:,5),'--g',data(:,1),data(:,6),':g',data(:,1),data(:,7),'g',...
%        data(:,1),data(:,8),'--r',data(:,1),data(:,9),':r',data(:,1),data(:,10),'r');
%     
%     legend(hdl, {'S1 Real','S1 Imaginary','S1 Magnitude', ...
%        'S2 Real','S2 Imaginary','S2 Magnitude', ...
%        'S1-S2 Real','S1-S2 Imaginary','S1-S2 Magnitude'},...
%        'Location','eastoutside');
    
    xlabel('Time [s]');
    ylabel('Signal [V]');
    

end


% ------------------- Close connections to equipment ----------------------
waveform_gen.output_off;
pump.stop;
sig_gen.level_off;

lock_in.close;
multimeter.close;
pump.close;
sig_gen.close;
% Close data file
fclose(fileID);


% -------------------------------------------------------------------------

print([filename(1:end-3) 'png'],'-dpng');
cd(folder);
fclose('all');