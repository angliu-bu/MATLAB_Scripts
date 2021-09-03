clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');


% --------------- Data recording parameters -------------------------------

file_base = ['ConductivityTest_' date '_200mMwater,Dye_Desalt_5upm'];


initial_notes = ...
    ['# Syringe size:\t10 mL \n' ...
    '# Resistor value:\t60400-ohm \n' ...
    ];


% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);


all_headers = ["Time[s]" ...
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

% -------------------------------------------------------------------------


fprintf(fileID, initial_notes);

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

% -------------------------------------------------------------------------

% Loop continues until 'Esc' key is pressed or pump volume is achieved.
while pressed_key ~= 27
    
    prev_time = time;
    % Record desired results
    time = 86400*now - start_time;

    % Add sensor 1 data to results
    results = [time ...
        lock_in.read_real ...
        lock_in.read_imaginary ...
        lock_in.read_magnitude ...
        ];
    
    % Write all results to file.
    dlmwrite(filename,results,'-append','Delimiter','\t');
    
    % Append latest results to data matrix
    data = [data; results];

    hdl = plot(data(:,1),data(:,2));
    legend('Real Part','Location','southoutside');
    
    xlabel('Time [s]');
    ylabel('Signal [V]');
    
    pause(0.05);
    

end


% ------------------- Close connections to equipment ----------------------

lock_in.close;

% Close data file
fclose(fileID);


% -------------------------------------------------------------------------

print([filename(1:end-3) 'png'],'-dpng');
cd(folder);
fclose('all');