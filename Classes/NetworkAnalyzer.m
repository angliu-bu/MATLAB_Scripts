classdef NetworkAnalyzer < handle
    properties
        address = 'GPIB1::16::1::INSTR';
        handle;
        
        start_frequency; % Sweep start frequency in Hz
        stop_frequency; % Sweep stop frequency in Hz
        
        trace_type=[ "NULL";"NULL" ]; % Choose trace type (linear, log, polar, real, imag)
        ref_level; % Reference level of analyzer in dBm
        sweep_time; % Sweep time in seconds
        power; % Power level in dBm
        power_state; % Power on or off
        S_parameter = ["NULL"; "NULL"]; % S-parameter of being measured
        continuous;
        
        n_points = 1601; % Max number of data points for analyzer
        res_BW; % Measurement bandwidth in Hz
        
        averaging;
        n_aver;
    end
    
    methods
        
        % Define object handle and open connection.
        function obj = open(obj)
            obj.handle = visa('ni',obj.address);
            obj.handle.InputBufferSize = 32*obj.n_points;
            fopen(obj.handle);
            obj.read_parameters;
        end
        
        % Read all parameters and update object for reference.
        function read_parameters(obj)
            obj.start_frequency = obj.get_start_frequency;
            obj.stop_frequency = obj.get_stop_frequency;
            obj.res_BW = obj.get_res_BW;
            obj.n_points = obj.get_n_points;
            obj.n_aver = obj.get_n_aver;
            obj.trace_type = [obj.get_trace_type(1); obj.get_trace_type(2)];
            obj.ref_level = obj.get_ref_level;
            obj.sweep_time = obj.get_sweep_time;
            [obj.power,obj.power_state] = obj.get_power;
            obj.S_parameter = [obj.get_S_parameter(1);obj.get_S_parameter(2)];
            obj.averaging = obj.get_averaging;
            obj.continuous = obj.get_continuous;
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
        
        % Set sweep start frequency in Hz
        function obj = set_start_frequency(obj,frequency)
            fprintf(obj.handle,[':SENS:FREQ:STAR ' num2str(frequency) ' HZ; ']);
            fprintf(obj.handle,[':SENS:FREQ:STAR?;']);
            obj.start_frequency = str2double(fscanf(obj.handle));
        end
        
        % Read start frequency in Hz
        function start_frequency = get_start_frequency(obj)
            fprintf(obj.handle,':SENS:FREQ:STAR?;');
            start_frequency = str2double(fscanf(obj.handle));
        end
        
        % Set sweep stop frequency in Hz
        function obj = set_stop_frequency(obj,frequency)
            fprintf(obj.handle,[':SENS:FREQ:STOP ' num2str(frequency) ' HZ; ']);
            fprintf(obj.handle,[':SENS:FREQ:STOP?;']);
            obj.stop_frequency = str2double(fscanf(obj.handle));
        end
        
        % Read stop frequency
        function stop_frequency = get_stop_frequency(obj)
            fprintf(obj.handle,':SENS:FREQ:STOP?;');
            stop_frequency = str2double(fscanf(obj.handle));
        end
        
        % Set number of points in sweep
        function obj = set_n_points(obj,n_points)
            fprintf(obj.handle,[':SENS:SWE:POIN ' num2str(n_points) '; ']);
            fprintf(obj.handle,':SENS:SWE:POIN?;');
            obj.n_points = str2num(fscanf(obj.handle));
        end
        
        % Read number of points in sweep
        function n_points = get_n_points(obj)
            fprintf(obj.handle,':SENS:SWE:POIN?;');
            n_points = str2double(fscanf(obj.handle));
        end
        
        % Set number of points for averaging
        function obj = set_n_aver(obj,n_aver)
            fprintf(obj.handle,[':SENS:AVER:COUN ' num2str(n_aver) ';']);
            fprintf(obj.handle,':SENS:AVER:COUN?;');
            obj.n_aver = str2num(fscanf(obj.handle));
        end
        
        function n_aver = get_n_aver(obj)
            fprintf(obj.handle,':SENS:AVER:COUN?;');
            n_aver = str2num(fscanf(obj.handle));
        end
        
        % Toggle averaging
        function obj = set_averaging(obj,averaging)
            fprintf(obj.handle,[':SENS:AVER ' averaging ';'])
            fprintf(obj.handle,':SENS:AVER?;');
            obj.averaging = str2double(fscanf(obj.handle));
        end
        
        % Read averaging state
        function averaging = get_averaging(obj)
            fprintf(obj.handle,':SENS:AVER?;');
            averaging = str2double(fscanf(obj.handle));
        end
        
        % Set measurement bandwidth
        function obj = set_res_BW(obj,res_BW)
            fprintf(obj.handle,[':SENS:BWID ' num2str(res_BW) ' HZ; ']);
            fprintf(obj.handle,':SENS:BWID?');
            obj.res_BW = str2double(fscanf(obj.handle));
        end
        
        % Set measurement bandwidth
        function res_BW = get_res_BW(obj)
            fprintf(obj.handle,':SENS:BWID?');
            res_BW = str2double(fscanf(obj.handle));
        end
        
        
        
        % Set trace type to 'MLIN', 'MLOG', 'SWR', 'PHAS', 'SMIT',
        % 'POL', 'GDEL', 'REAL', 'IMAG', 'MIMP'
        function obj = set_trace_type(obj,trace,trace_type)
            fprintf(obj.handle,[':CALC' num2str(trace) ':FORM ' trace_type ';']);
            fprintf(obj.handle,[':CALC' num2str(trace) ':FORM?']);
            resp = fscanf(obj.handle);
            obj.trace_type(trace) = string(resp(1:end-1));
        end
        
        % Read trace type
        function trace_type = get_trace_type(obj,trace)
            fprintf(obj.handle,[':CALC' num2str(trace) ':FORM?']);
            resp = fscanf(obj.handle);
            trace_type = string(resp(1:end-1));
        end
        
        
        % Set S-parameter to S11, S21, S12, or S22
        function obj = set_S_parameter(obj,trace,S_parameter)
            fprintf(obj.handle,['SENS' num2str(trace) ':STAT ON;']);
            fprintf(obj.handle,[char(strcat(":SENS",num2str(trace),":FUNC 'XFR:S ")) S_parameter(2) ',' S_parameter(3) char("'; DET NBAN;*WAI;")]);
            obj.S_parameter(trace) = obj.get_S_parameter(trace);
        end
        
        % Read S-parameter
        function S_parameter = get_S_parameter(obj,trace)
            fprintf(obj.handle,[':SENS'  num2str(trace) ':FUNC?;']);
            resp = fscanf(obj.handle);
            S_parameter = string(['S' resp(end-4) resp(end-2)]);
        end
        
        
        % Set reference level (i.e. max signal size)
        function obj = set_ref_level(obj,ref_level)
            if ref_level ~= 'AUTO'
                fprintf(obj.handle,[':DISP:WIND1:TRAC:Y:RLEV ' num2str(ref_level) ';']);
            else
                fprintf(obj.handle,[':DISP:WIND1:TRAC:Y:AUTO ONCE;']);
            end
            fprintf(obj.handle,[':DISP:WIND1:TRAC:Y:RLEV?;']);
            obj.ref_level = str2double(fscanf(obj.handle));
        end
        
        % Read reference level
        function ref_level = get_ref_level(obj)
            fprintf(obj.handle,[':DISP:WIND1:TRAC:Y:RLEV?;']);
            ref_level = str2double(fscanf(obj.handle));
        end
            
        
        
        % Set sweep time in seconds, or set to 'AUTO'
        function set_sweep_time(obj,sweep_time)
            if sweep_time ~= 'AUTO'
                fprintf(obj.handle,[':SENS:SWE:TIME:AUTO OFF;']);
                fprintf(obj.handle,[':SENS:SWE:TIME ' num2str(sweep_time) ' S;']);
            else
                fprintf(obj.handle,[':SENS:SWE:TIME:AUTO ON;']);
            end
            fprintf(obj.handle,':SENS:SWE:TIME?;');
            obj.sweep_time = str2double(fscanf(obj.handle));
        end
        
        % Measure sweep time
        function sweep_time = get_sweep_time(obj)
            fprintf(obj.handle,':SENS:SWE:TIME?;');
            sweep_time = str2double(fscanf(obj.handle));
        end
        
        % Set power level
        function obj = set_power(obj,power)
            if numel(power) == 1
                fprintf(obj.handle,[':SOUR:POW ' num2str(power) ' dBm;']);
            else
                fprintf(obj.handle,['OUTP ' power ';']);
            end
            fprintf(obj.handle,[':SOUR:POW?;']);
            obj.power = str2double(fscanf(obj.handle));
            
            fprintf(obj.handle,'OUTP?;');
            obj.power_state = str2double(fscanf(obj.handle));
        end
        
        % Read power level and state
        function [power, power_state] = get_power(obj)
            fprintf(obj.handle,[':SOUR:POW?;']);
            power = str2double(fscanf(obj.handle));
            
            fprintf(obj.handle,'OUTP?;');
            power_state = str2double(fscanf(obj.handle));
        end
        
        % Read trace
        function trace = get_trace(obj,trace)
            fprintf(obj.handle,[':TRACE:DATA? CH' num2str(trace) 'FDATA;']);
            signal = str2num(fscanf(obj.handle));
            freqs = obj.start_frequency:(obj.stop_frequency - obj.start_frequency)/(obj.n_points-1):obj.stop_frequency;
            trace = [freqs' signal'];
        end
        
        % Move marker to peak and output frequency and signal value.
        function peak_value = get_peak_value(obj)
            fprintf(obj.handle,':CALC:MARK1:MAX; :CALC:MARK1:Y?;');
            peak_value = str2num(fscanf(obj.handle));
            fprintf(obj.handle,':CALC:MARK1:X?;');
            peak_value = [str2num(fscanf(obj.handle)) peak_value];
        end
        
        % Toggle continuous measurement (options 'ON' or 'OFF')
        function obj = set_continuous(obj,continuous)
            fprintf(obj.handle,['ABOR;:INIT1:CONT ' continuous ';*WAI;'])
            obj.continuous = obj.get_continuous;
        end
        % Read measurement state
        function continuous = get_continuous(obj)
            fprintf(obj.handle,':INIT1:CONT?;*WAI;');
            continuous = str2num(fscanf(obj.handle));
            if boolean(continuous)
                continuous = 'ON';
            else
                continuous = 'OFF';
            end
        end
        
        % Trigger measurement
        function trigger(obj)
            fprintf(obj.handle,'ABOR;:INIT1;*WAI;');
        end 
    end
end