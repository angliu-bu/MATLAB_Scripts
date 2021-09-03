clear, clc, instrreset;

lock_in = visa('ni','GPIB0::1::1::INSTR');
fopen(lock_in);

filename = 'ConductivityTest_04-26-2017_3.txt';
fileID = fopen(filename,'w');
head_string = '#Time[s]\tReal[V]\tImag[V]\tMag[V]\n';
fprintf(fileID,head_string);

t_max = 10;

start_time = now*86400;
curr_time = start_time;

i = 1;

h=figure('KeyPressFcn','keep=0');
keep = 1;

while keep == 1
    curr_time = 86400*now;
    times(i) = curr_time - start_time;
    
    % Measure and record real part of signal
    fprintf(lock_in,"OUTP?1;");
    real_part(i) = str2double(fscanf(lock_in));
    
    % Measure and record imaginary part of signal
    fprintf(lock_in,"OUTP?2;");
    imag_part(i) = str2double(fscanf(lock_in));
    
    % Measure and record magnitude of signal
    fprintf(lock_in,"OUTP?3;");
    magnitude(i) = str2double(fscanf(lock_in));
    
    fprintf(fileID,'%.10f\t%.10f\t%.10f\t%.10f\n',times(i),real_part(i),imag_part(i),magnitude(i));
    
    n_elements = 750;
    if numel(times) <= n_elements
        plot(times,real_part,times,imag_part,times,magnitude);
    else
        plot(times(end-n_elements:end),real_part(end-n_elements:end),times(end-n_elements:end),imag_part(end-n_elements:end),times(end-n_elements:end),magnitude(end-n_elements:end));
    end
    pause(0.005);
    
    i = i+1;
end

fclose(lock_in);
fclose(fileID);

