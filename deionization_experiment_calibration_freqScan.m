clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');

% --------------- Data recording parameters -------------------------------

pump_rate = 100; % Syringe pump flow rate in uL/min

S1_on = true;
S2_on = true;
S1S2_on = true;


file_base = ['ConductivityTest_' date '_ChannelClean_' num2str(pump_rate) 'upm'];
file_headers = sprintf('# Time [s]\tS1_Real[V]\tS1_Imag[V]\tS1_Mag[V]\tS2_Real[V]\tS2_Imag[V]\tS2_Mag[V]\tS1-S2_Real[V]\tS1-S2_Imag[V]\tS1-S2_Mag[V]\tRate[uL/min]\tFrequency[Hz]\tDI_volt[V]\n');

initial_notes = ...
    ['# Concentration:\t2,5,10,20,40,60,80,100,120,140,160,180,200 mM \n' ...
    '# Syringe size:\t1 mL \n' ...
    '# Resistor value:\t301-ohm \n' ...
    '# Top electrode grounded \n' ...
    ];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

allowed_freq = [50e3:50e3:2e6];
freq_number = 1;
scan_freq = false;

fprintf(fileID, initial_notes);
fprintf(fileID, file_headers);

% --------------- Define and connect to all equipment ---------------------
lock_in = SR844_LockIn;
%multimeter = HP3478A_Multimeter;
pump = ChemyxSyringePump;
sig_gen = SignalGenerator;
sensorSwitch = arduino;

lock_in.open;
%multimeter.open;
pump.open;
sig_gen.open;


% -------------------------------------------------------------------------


% --------------- Set signal generator parameters -------------------------

sig_gen.set_frequency(allowed_freq(freq_number));
sig_gen.level_on;


% -------------------------------------------------------------------------

% ---------------- Set arduino to sensor 1 --------------------------------

writeDigitalPin(sensorSwitch,'D2',0);
writeDigitalPin(sensorSwitch,'D3',0);
delay_time = 0.050; % delay before measurement.

% -------------------------------------------------------------------------



% ----------------- Set Syringe pump parameters ---------------------------

pump.set_units(2);
pump.set_volume(-10000);
pump.set_rate(pump_rate);

% -------------------------------------------------------------------------

% Record start time of experiment
start_time = now*86400;

% Create data matrix for plotting
data = [];

% Define what happens when key is pressed. To be used for killing loop.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');

pump.start;
pause(0.5);

% Press escape to exit loop
while pressed_key ~= 27
    % Record desired results
    
    % Switch to sensor 1
    writeDigitalPin(sensorSwitch,'D2',0);
    writeDigitalPin(sensorSwitch,'D3',0);
    pause(delay_time);
    
    % Add sensor 1 data to results
    results = [86400*now - start_time ...
        lock_in.read_real ...
        lock_in.read_imaginary ...
        lock_in.read_magnitude ...
        ];
    
    
    % Switch to sensor 2
    writeDigitalPin(sensorSwitch,'D2',1);
    writeDigitalPin(sensorSwitch,'D3',0);
    pause(delay_time);
    
    % Add sensor 2 data to results
    results = [results ...
        lock_in.read_real ...
        lock_in.read_imaginary ...
        lock_in.read_magnitude ...
        ];
    
    
    % Switch to S1-S2
    writeDigitalPin(sensorSwitch,'D2',0);
    writeDigitalPin(sensorSwitch,'D3',1);
    pause(delay_time);
    
    % Add differential data to results
    results = [results ...
        lock_in.read_real ...
        lock_in.read_imaginary ...
        lock_in.read_magnitude ...
        ];
    
    % Add operation parameters to results
    results = [results ...
        pump.rate ...
        lock_in.read_frequency ...
        ];
    
    
    
    
    
    if pressed_key == 30
        freq_number = mod(freq_number,numel(allowed_freq)) + 1;
        
        sig_gen.set_frequency(allowed_freq(freq_number));
        disp(['Frequency set to ' num2str(allowed_freq(freq_number)) ' Hz']);
        pressed_key = 0;
    end
    
    if pressed_key == 31
        if freq_number - 1 > 0
            freq_number = freq_number - 1;
        else
            freq_number = numel(allowed_freq);
        end
        
        sig_gen.set_frequency(allowed_freq(freq_number));
        disp(['Frequency set to ' num2str(allowed_freq(freq_number)) ' Hz']);
        pressed_key = 0;
    end
    
    
    
    if pressed_key == 13
        scan_freq = true;
        scan_start_time = results(1);
        freq_number = 0;
        first_item = true;
        pressed_key = 0;
    end
    

    
    dwell_time = 5; % Dwell time of sweep in seconds
    if scan_freq && results(1) - scan_start_time >= dwell_time*freq_number
        freq_number = mod(freq_number,numel(allowed_freq)) + 1;
        sig_gen.set_frequency(allowed_freq(freq_number));
        disp(['Frequency set to ' num2str(allowed_freq(freq_number)) ' Hz']);
        
        if freq_number == 1 && first_item ~= true
            scan_freq = false;
        end
        
        first_item = false;
    end
    
    % Write all results to file.
    dlmwrite(filename,results,'-append','Delimiter','\t');
    
    
    % Append latest results to data matrix
    data = [data; results];

    
    hdl = plot(data(:,1),data(:,2),'--b', data(:,1),data(:,3),':b',data(:,1),data(:,4),'b',...
        data(:,1),data(:,5),'--g',data(:,1),data(:,6),':g',data(:,1),data(:,7),'g',...
        data(:,1),data(:,8),'--r',data(:,1),data(:,9),':r',data(:,1),data(:,10),'r');
    
    xlabel('Time [s]');
    ylabel('Signal [V]');
    
    legend(hdl, {'S1 Real','S1 Imaginary','S1 Magnitude', ...
        'S2 Real','S2 Imaginary','S2 Magnitude', ...
        'S1-S2 Real','S1-S2 Imaginary','S1-S2 Magnitude'},...
        'Location','eastoutside');
end

pump.stop;

print([filename(1:end-3) 'png'],'-dpng');


% Close data file
fclose(fileID);

% ------------------- Close connections to equipment ----------------------
sig_gen.level_off;
lock_in.close;
%multimeter.close;
pump.close;
sig_gen.close;

% -------------------------------------------------------------------------
%dos(['notepad ' filename]);
cd(folder);
fclose('all');