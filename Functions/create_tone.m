function tone = create_tone(freq,A,T)

    Fs = 192000; % Sampling frequency of speaker

    t = 0:1/Fs:T;               % Create tone time series
    y = A*sin(2*pi*freq*t);     % Generate tone signal
    tone = audioplayer(y,Fs);   % API for creating tone
    
    
    play(tone); % Start playing tone
    
end