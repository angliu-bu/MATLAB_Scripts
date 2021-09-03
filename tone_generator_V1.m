clear, clc, instrreset;

% Open connection to spectrum analyzer
spectrum_analyzer = visa('ni','GPIB0::18::8::INSTR');
signal_generator = visa('ni','GPIB0::28::1::INSTR');

fopen(spectrum_analyzer);
fopen(signal_generator);
fileID = fopen('SidebandSize_15.168MHzMode_FreqSweep_28-04-2017_2.txt','w'); % Open data file to write to


fprintf(signal_generator,":LEVEL ON;");
pause(600); % Wait for 10 minutes for signal generator to warm up.

result_string = sprintf('#Freq[Hz]\tResp [V]'); % Print headers for results
fprintf(fileID,[result_string '\n']); % Write headers to file
disp(result_string); % Display headers in terminal

i=1;
for n=1:1
    for freq = [15000:-500:5000 4750:-250:1000 975:-25:150] % Frequency of tone in Hz
        A = 1; % Sound amplitude
        T = 220; % Time length of sound
        Fs = 192000; % Sampling frequency of speaker
        
        t = 0:1/Fs:T;               % Create tone time series
        y = A*sin(2*pi*freq*t);     % Generate tone signal
        tone = audioplayer(y,Fs);   % API for creating tone
        
        f0 = 15168000; % Resonator driving frequency in Hz
        span = 10;  % Frequency span of analyzer in Hz
        f_start = f0 + freq - span/2;
        f_stop = f0 + freq + span/2;
        
        % Define command to change plot range
        analyzer_command =[':INIT:REST; :SENS:FREQ:STAR ' num2str(f_start) ' HZ; :SENS:FREQ:STOP ' num2str(f_stop) ' HZ;'];
        
        % Send command to spectrum analyzer
        fprintf(spectrum_analyzer,analyzer_command);
        
        
        play(tone); % Start playing tone
        pause(0.95*T); % Wait for 95% of length of tone
        
        % Move marker to largest peak and measure it
        fprintf(spectrum_analyzer,":CALC:MARK1:MAX; :CALC:MARK1:Y?;");
        pause(0.1); % Wait for computer briefly
        results = str2num(fscanf(spectrum_analyzer)); % Read voltage at marker
        all_results(i)=results;
        
        result_string = sprintf('%0.10f\t%0.9f',freq,results); % Define results string
        disp(result_string); % Write results to terminal
        fprintf(fileID,[result_string '\n']); % Write results to file
        stop(tone); % Stop playing tone
        
        i = i+1;
    end
end

fprintf(signal_generator,":LEVEL OFF;");

fclose(spectrum_analyzer); % Close connection to analyzer
fclose(signal_generator);
fclose(fileID); % Close data file
disp('Done.'); % Inform user that script has finished.


    %%
    A = 1:-0.05:0.1