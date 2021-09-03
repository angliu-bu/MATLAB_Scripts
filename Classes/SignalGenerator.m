classdef SignalGenerator < handle
    properties
        address = 'GPIB1::28::1::INSTR';
        handle;
        
        % Normal use parameters
        frequency,power,level;
        
        % Scan parameters
        start_frequency, stop_frequency, step_size, dwell_time;
    end
    
    methods
        
        % Define object handle and open connection.
        function obj = open(obj)
            obj.handle = visa('ni',obj.address);
            fopen(obj.handle);
            obj.read_parameters;
        end
        
        % Read all parameters and update object for reference.
        function read_parameters(obj)
            fprintf(obj.handle,'RF?;');
            obj.frequency = fscanf(obj.handle);
            obj.frequency = str2num(obj.frequency(6:end-1));
            
            fprintf(obj.handle,'LEVEL?;');
            obj.power = fscanf(obj.handle);
            if string(obj.power(7:end-1)) == "OFF"
                obj.level_on;
                fprintf(obj.handle,'LEVEL?;');
                obj.power = fscanf(obj.handle);
                obj.level_off;
            else
                obj.level = 'ON';
            end
            obj.power = str2num(obj.power(7:end-1));
            
            fprintf(obj.handle,'RF:STA?;');
            obj.start_frequency = fscanf(obj.handle);
            obj.start_frequency = str2num(obj.start_frequency(13:end-1));
            
            fprintf(obj.handle,'RF:STO?;');
            obj.stop_frequency = fscanf(obj.handle);
            obj.stop_frequency = str2num(obj.stop_frequency(9:end-1));
            
            fprintf(obj.handle,'RF:STE?;');
            obj.step_size = fscanf(obj.handle);
            obj.step_size = str2num(obj.step_size(12:end-1));
            
            fprintf(obj.handle,'TIME?;');
            obj.dwell_time = fscanf(obj.handle);
            obj.dwell_time = 1000*str2num(obj.dwell_time(15:end-1));
        end
        
        % Close connection
        function close(obj)
            fclose(obj.handle);
        end
        
        % Reset to defaults
        function reset(obj)
            fprintf(obj.handle,':PRES;');
            obj.read_parameters;
        end
        
        % Set sig gen level to on
        function obj = level_on(obj)
            fprintf(obj.handle,'LEVEL ON;');
            obj.level = 'ON';
        end
        
        % Set sig gen level to off
        function obj = level_off(obj)
            fprintf(obj.handle,'LEVEL OFF;');
            obj.level = 'OFF';
        end
        
        % Set frequency in Hz
        function obj = set_frequency(obj,frequency)
            fprintf(obj.handle,['RF ' num2str(frequency) ' HZ; ']);
            obj.frequency = frequency;
        end
        
        % Set power in dBm
        function obj = set_power(obj,power)
            fprintf(obj.handle,['LEVEL ' num2str(power) ' DBM; ']);
            obj.power = power;
            obj.level = 'ON';
        end
        
        % Set power in dBm
        function obj = set_voltage(obj,voltage)
            fprintf(obj.handle,['LEVEL ' num2str(voltage) ' V; ']);
            obj.power = voltage;
            obj.level = 'ON';
        end
        
        % Reset sweep
        function reset_sweep(obj)
            fprintf(obj.handle,'SWP:R;');
        end
        
        % Turn sweep on
        function obj = sweep_on(obj)
            fprintf(obj.handle,'SWP ON;');
        end
        
        % Turn sweep off
        function obj = sweep_off(obj)
            fprintf(obj.handle,'SWP OFF;');
        end
        
        % Set sweep start frequency in Hz
        function obj = set_start_frequency(obj,frequency)
            fprintf(obj.handle,['RF:STA ' num2str(frequency) ' HZ; ']);
            obj.start_frequency = frequency;
        end
        
        % Set sweep stop frequency in Hz
        function obj = set_stop_frequency(obj,frequency)
            fprintf(obj.handle,['RF:STO ' num2str(frequency) ' HZ; ']);
            obj.stop_frequency = frequency;
        end
        
        % Set sweep step size in Hz
        function obj = set_step_size(obj,frequency)
            fprintf(obj.handle,['RF:STE ' num2str(frequency) ' HZ; ']);
            obj.step_size = frequency;
        end
        
        % Set sweep dwell time in ms
        function obj = set_dwell_time(obj,time)
            fprintf(obj.handle,['TIME ' num2str(time) ' MS; ']);
            obj.dwell_time = time;
        end
        
        % Send arbitrary command
        function obj = send_command(obj,command)
            fprintf(obj.handle,command);
        end
    end
end
