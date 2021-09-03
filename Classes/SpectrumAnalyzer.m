classdef SpectrumAnalyzer < handle
    properties
        address = 'GPIB1::18::1::INSTR';
        handle;
        
        start_frequency; % Sweep start frequency in Hz
        stop_frequency; % Sweep stop frequency in Hz
        
        y_scale; % Choose y scale (options are 'LIN' or 'LOG')
        trace_type; % Choose trace type ('WRIT', 'AVER', 'MAXH', or 'MINH')
        ref_level; % Reference level of analyzer in dBm
        
        n_points = 40001; % Number of data points
        res_BW; % Measurement bandwidth in Hz

        n_aver;
    end
    
    methods
        
        % Define object handle and open connection.
        function obj = open(obj)
            obj.handle = visa('ni',obj.address);
            obj.handle.InputBufferSize = 32*obj.n_points;
            fopen(obj.handle);
            obj.restart;
            obj.read_parameters;
        end
        
        % Read all parameters and update object for reference.
        function read_parameters(obj)
            fprintf(obj.handle,':SENS:FREQ:STAR?');
            obj.start_frequency = str2num(fscanf(obj.handle));
            
            fprintf(obj.handle,':SENS:FREQ:STOP?');
            obj.stop_frequency = str2num(fscanf(obj.handle));
            
            fprintf(obj.handle,':SENS:BWID:RES?');
            obj.res_BW = str2num(fscanf(obj.handle));
            
            fprintf(obj.handle,':SENS:SWE:POIN?');
            obj.n_points = str2num(fscanf(obj.handle));
            
            fprintf(obj.handle,':SENS:AVER:COUN?');
            obj.n_aver = str2num(fscanf(obj.handle));
            
            fprintf(obj.handle,':DISP:WIND:TRAC:Y:SPAC?');
            obj.y_scale = fscanf(obj.handle);
            obj.y_scale = obj.y_scale(1:3);
            
            fprintf(obj.handle,':TRAC:TYPE?');
            obj.trace_type = fscanf(obj.handle);
            obj.trace_type = obj.trace_type(1:4);
            
            fprintf(obj.handle,':DISP:WIND:TRAC:Y:RLEV?');
            obj.ref_level = str2num(fscanf(obj.handle));
            if obj.y_scale == 'LIN'
                obj.ref_level = 10*log10(obj.ref_level^2/0.05);
            end
            
        end
        
        % Close connection
        function close(obj)
            fclose(obj.handle);
        end
        
        % Reset to defaults
        function reset(obj)
            fprintf(obj.handle,':SYST:PRES;');
            obj.read_parameters;
        end
        
        % Restart measurement
        function restart(obj)
            fprintf(obj.handle,':INIT:REST;');
        end
        % Set sweep start frequency in Hz
        function obj = set_start_frequency(obj,frequency)
            fprintf(obj.handle,[':SENS:FREQ:STAR ' num2str(frequency) ' HZ; ']);
            obj.start_frequency = frequency;
        end
        
        % Set sweep stop frequency in Hz
        function obj = set_stop_frequency(obj,frequency)
            fprintf(obj.handle,[':SENS:FREQ:STOP ' num2str(frequency) ' HZ; ']);
            obj.stop_frequency = frequency;
        end
        
        % Set sweep step size in Hz
        function obj = set_n_points(obj,n_points)
            fprintf(obj.handle,[':SENS:SWE:POIN ' num2str(n_points) '; ']);
            obj.n_points = n_points;
        end
        
        % Set number of points for averaging
        function obj = set_n_aver(obj,n_aver)
            fprintf(obj.handle,[':SENS:AVER:COUN ' num2str(n_aver) ';']);
            obj.n_aver = n_aver;
        end
        
        % Set measurement bandwidth
        function obj = set_res_BW(obj,res_BW)
            fprintf(obj.handle,[':SENS:BWID:RES ' num2str(res_BW) ' HZ; ']);
            obj.res_BW = res_BW;
        end
        
        % Set y scale
        function obj = set_y_scale(obj,y_scale)
            fprintf(obj.handle,[':DISP:WIND:TRAC:Y:SPAC ' y_scale '; ']);
            obj.y_scale = y_scale;
        end
        

        function obj = set_trace_type(obj,trace_type)
            fprintf(obj.handle,[':TRAC:TYPE ' trace_type ';']);
            obj.trace_type = trace_type;
        end
        
        % Set reference level (i.e. max signal size) in dBm
        function obj = set_ref_level(obj,ref_level)
            fprintf(obj.handle,[':DISP:WIND:TRAC:Y:RLEV ' num2str(ref_level) ' dBm;']);
            obj.ref_level = ref_level;
        end
        
        % Measure sweep time
        function sweep_time = get_sweep_time(obj)
            fprintf(obj.handle,':SENS:SWE:TIME?;');
            sweep_time = str2double(fscanf(obj.handle));
        end
        
        % Save data from trace 1
        function save_data(obj, filename)
            fileID = fopen(filename, 'w');
            fprintf(fileID,'# Freq[Hz]\tSignal\n');
            freqs = [obj.start_frequency:(obj.stop_frequency-obj.start_frequency)/(obj.n_points-1):obj.stop_frequency];
            
            fprintf(obj.handle,':TRAC:DATA? TRACE1;');
            data = str2num(fscanf(obj.handle));
            
            for i=1:obj.n_points
                fprintf(fileID,'%.10f\t%.10f\n',freqs(i),data(i));
            end
            fclose(fileID);
        end
        
        % Display graph of trace on screen. If output==true, output data
        % from trace to a matrix.
        function results = display_data(obj,output)
            freqs = [obj.start_frequency:(obj.stop_frequency-obj.start_frequency)/(obj.n_points-1):obj.stop_frequency];
            fprintf(obj.handle,':TRAC:DATA? TRACE1;');
            data = str2num(fscanf(obj.handle));

            plot(freqs,data);
            if output
                results = [freqs' 1000*data'];
            end
        end
        

        % Set attenuation in dBm
        function set_attenuation(obj, attenuation)
            fprintf(obj.handle,[':SENS:POW:RF:ATT ' num2str(attenuation) ';']);
        end
        
        % Move marker to peak and output signal value.
        function peak_value = get_peak_value(obj)
            fprintf(obj.handle,':CALC:MARK1:MAX; :CALC:MARK1:Y?;');
            peak_value = str2num(fscanf(obj.handle));
        end
        
        % Move marker to peak and return frequency.
        function peak_freq = get_peak_freq(obj)
            fprintf(obj.handle,':CALC:MARK1:MAX; :CALC:MARK1:X?;');
            peak_freq = str2num(fscanf(obj.handle));
        end
    end
end