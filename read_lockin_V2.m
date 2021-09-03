clear, clc, instrreset;

cd('C:\Users\USER\Desktop\ExperimentFiles\Joe\MATLAB Scripts');


% File naming parameters
file_base = ['120.6MHz_VaryDC_' date];

% Create new file. Output handle, filename, and folder.
[fileID,filename,folder] = name_file(file_base);

file_headers = sprintf("# Time[s]\tReal[V]\tImag[V]\tMag[V]\n");
fprintf(fileID,file_headers);



% Create lock-in amplifier object
lock_in = SR844_LockIn;

% Open connections to instruments
lock_in.open;

% Detect key pressed during experiment.
pressed_key = 0;
h=figure('KeyPressFcn','pressed_key=double(get(h,char("CurrentCharacter")));');

data = [];

wait_time = 0.1;
start_time = now;
curr_time = 0;
max_time = 3600;

while curr_time < max_time
    
    if pressed_key == 27
        break;
    end
    
    curr_time = (now-start_time)*86400;

    
    
    % Wait long enough for data to collect
    pause(wait_time);

    results = [curr_time lock_in.read_real lock_in.read_imaginary lock_in.read_magnitude];
    data = [data; results];
    
    dlmwrite(filename,results,'-append','Delimiter','\t');
    hdl = plot(data(:,1),1000*data(:,2));
    legend(hdl,{'Real'},'Location','eastoutside');
    
    xlabel('Time [s]');
    ylabel('Signal [mV]');
end

print([filename(1:end-3) 'png'],'-dpng');

lock_in.close;
fclose('all');