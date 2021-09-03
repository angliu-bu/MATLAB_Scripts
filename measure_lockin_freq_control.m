clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');


% --------------- Data recording parameters -------------------------------

file_base = ['Calibration_' date '_200mMwater'];

frequencies = [20e3:10e3:100e3 125e3:25e3:1e6 1.25e6:0.25e6:10e6 12.5e6:2.5e6:100e6];
f_index = 1;

initial_notes = ...
    ['# Measurement of 200 mM water, no fluid flow. Frequency dependent \n'...
    '# measurment. \n' ...
    ];


% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);


all_headers = ["Freq[Hz]" ...
    "Real[V]" ...
    "Imag[V]" ...
    "Mag[V]" ...
    ];

file_headers = "#";
for i=1:numel(all_headers);
    file_headers = sprintf('%s\t%s',file_headers,all_headers(i));
end
file_headers = sprintf('%s\n',file_headers);

% --------------- Define and connect to all equipment ---------------------
lock_in = SR844_LockIn;
lock_in.open;

sig_gen = SignalGenerator;
sig_gen.open;

% -------------------------------------------------------------------------

sig_gen.set_frequency(frequencies(f_index));
sig_gen.set_power(19);


fprintf(fileID, initial_notes);

% -------------------------------------------------------------------------


% -------------------------- Initialize parameters ------------------------

% Create data matrix for plotting
data = [];
results = [];

% Detect key pressed during experiment.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');

% -------------------------------------------------------------------------

% Loop continues until 'Esc' key is pressed or pump volume is achieved.
for frequencies=[20e3:10e3:100e3 125e3:25e3:1e6 1.25e6:0.25e6:10e6 12.5e6:2.5e6:100e6]
    
    sig_gen.set_frequency(frequencies);
    pause(5);
    
    results = [lock_in.read_frequency ...
        lock_in.read_real ...
        lock_in.read_imaginary ...
        lock_in.read_magnitude ...
        ];
    
    % Write all results to file.
    dlmwrite(filename,results,'-append','Delimiter','\t');
    
    % Append latest results to data matrix
    data = [data; results];
    
    hdl = plot(data(:,1),data(:,2),data(:,1),data(:,3));
    legend({'Real Part','Imaginary Part'},'Location','southoutside');
    
    xlabel('Freq [Hz]');
    ylabel('Signal [V]');
     
    
    
    
    
    

end


% ------------------- Close connections to equipment ----------------------

sig_gen.level_off;

lock_in.close;
sig_gen.close;

% Close data file
fclose(fileID);


% -------------------------------------------------------------------------

print([filename(1:end-3) 'png'],'-dpng');
cd(folder);
fclose('all');