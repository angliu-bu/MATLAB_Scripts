clear, clc, instrreset;

lock_in = visa('ni','GPIB0::1::2::INSTR'); % Create lock-in amplifier handle
multimeter = visa('ni','GPIB0::23::1::INSTR'); % Create multimeter handle

fopen(lock_in); % Open connection to lock-in amplifier
fopen(multimeter); % Open connection to multimeter

filename = 'Data\ConductivityTest_5-May-2017_outlet_3.txt'; % Define Filename

fileID = fopen(filename,'w'); % Create the file to write
head_string = '#Time[s]\tReal[V]\tImag[V]\tMag[V]\tDI_Volt[V]\n'; % Define Column headers
% Allow user to add notes if desired.
notes = ['# '];

fprintf(fileID, notes); % Write notes to top of file
fprintf(fileID,head_string); % Write column headers to file


start_time = now*86400; % Measure the start time in seconds
curr_time = start_time; % Define the current time as the start time

i = 1; % Define indexing variable

% Define what happens when key is pressed
h=figure('KeyPressFcn','keep=0');
keep = 1;

% While loop will continue to run until a key is pressed.
while keep == 1
    curr_time = 86400*now; % Measure time in seconds
    times(i) = curr_time - start_time; % Calculate elapsed time
    
    % Measure and record deionization electrode voltage from multimeter
    di_voltage(i) = str2double(fscanf(multimeter));
    
    % Measure and record real part of signal
    fprintf(lock_in,"OUTP?1;");
    real_part(i) = str2double(fscanf(lock_in));
    
    % Measure and record imaginary part of signal
    fprintf(lock_in,"OUTP?2;");
    imag_part(i) = str2double(fscanf(lock_in));
    
    % Measure and record magnitude of signal
    fprintf(lock_in,"OUTP?3;");
    magnitude(i) = str2double(fscanf(lock_in));
    
    % Write results to file
    fprintf(fileID,'%.10f\t%.10f\t%.10f\t%.10f\t%.10f\n',times(i),real_part(i),imag_part(i),magnitude(i),di_voltage(i));
    
    n_elements = 750; % Number of data points to plot in realtime
    
    % Plot latest n_elements. If fewer points have been measured, plot
    % all points
    if numel(times) <= n_elements
        plot(times,real_part,times,imag_part,times,magnitude,times,di_voltage/1000);
    else
        plot(times(end-n_elements:end),real_part(end-n_elements:end),times(end-n_elements:end),imag_part(end-n_elements:end),times(end-n_elements:end),magnitude(end-n_elements:end));
    end
    
    pause(0.005); % Wait 5 ms. Allows computer to determine if key has been pressed
    
    i = i+1; % Increment the index
end

fclose(lock_in); % Close connection to the lock-in amplifier
fclose(fileID); % Close data file
fclose(multimeter); % Close connection to the multimeter.
