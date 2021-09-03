classdef ChemyxSyringePump < handle
    properties
        address = 'COM4';
        handle;
        rate;
        mode; % Options are "withdrawal" or "infusion"
        volume;
        units; %0=mL/min, 1=ml/hr, 2=uL/min, 3=uL/hr
        diameter; % syringe diameter in mm
        primerate;
        time;
        time_delay;
        
        MAX_RATE; % Max allowed flow rate
        MIN_RATE; % Min allowed flow rate
        MAX_VOLUME; % Max allowed volume
        MIN_VOLUME; % Min allowed volume
        
        verbose = false; % Give updates as parameters are changed
        
    end
    methods
        % Open connection to pump and initialize all essential parameters
        function obj = open(obj)
            obj.handle = serial(obj.address);
            set(obj.handle,'BaudRate',38400);
            set(obj.handle,'Terminator','CR/LF');
            fopen(obj.handle);
            pause(0.5);
            
            % Read current pump parameters
            obj.update_parameters;
            
            % Since volume returned by 'view parameter' command is always
            % positive and there is no other command to obtain mode, set
            % mode to infusion by default with the volume that was read
            % from syringe pump.
            obj.set_volume(obj.volume);
        end
        
        % Close connection to pump
        function close(obj)
            fclose(obj.handle);
        end
        
        % Read operation parameters from pump and update object.
        function obj = update_parameters(obj)
            pause(0.5);
            fprintf(obj.handle,'view parameter');
            fscanf(obj.handle); % Ignore first line
            
            % Read units from pump
            obj.units = fscanf(obj.handle);
            obj.units = str2double(obj.units(9:end-3));
            
            % Read syringe diameter from pump
            obj.diameter = fscanf(obj.handle);
            obj.diameter = str2double(obj.diameter(8:end-3));
            
            % Read flow rate from pump
            obj.rate = fscanf(obj.handle);
            obj.rate = str2double(obj.rate(8:end-3));
            
            % Read primerate from pump
            obj.primerate = fscanf(obj.handle);
            obj.primerate = str2double(obj.primerate(13:end-3));
            
            % Read infusion/withdrawal time from pump
            obj.time = fscanf(obj.handle);
            obj.time = str2double(obj.time(8:end-3));
            
            % Read infusion/withdrawal volume from pump
            obj.volume = fscanf(obj.handle);
            obj.volume = str2double(obj.volume(10:end-3));
                        
            % Read time delay from pump
            obj.time_delay = fscanf(obj.handle);
            obj.time_delay = str2double(obj.time_delay(9:end-2));
            
            fprintf(obj.handle, 'read limit parameter');
            fscanf(obj.handle); % Ignore line
            
            % Obtain maximum and minimum allowed parameters
            all_limits = str2num(fscanf(obj.handle));
            obj.MAX_RATE = all_limits(1);
            obj.MIN_RATE = all_limits(2);
            obj.MAX_VOLUME = all_limits(3);
            obj.MIN_VOLUME = all_limits(4);
        end
        
        % Start pump
        function start(obj)
            pause(0.5);
            fprintf(obj.handle, 'start');
            
            if obj.verbose
                disp('Pump started');
            end
        end
        
        % Pause pump. Run can be continued by using start command
        function pause(obj)
            pause(0.5);
            fprintf(obj.handle, 'pause');
            
            if obj.verbose
                disp('Pump paused');
            end
        end
        
        % Stop pump. Using start command will restart run from beginning
        function stop(obj)
            pause(0.5);
            fprintf(obj.handle, 'stop');
            
            if obj.verbose
                disp('Pump stopped');
            end
        end
            
        % Set flow rate
        function obj = set_rate(obj,rate)
            pause(0.5);
            
            % Check if new rate is allowed. If limit exceeded, set to limit
            if rate > obj.MAX_RATE
                rate = obj.MAX_RATE;
                disp('Maximum allowed flow rate exceeded');
            end
            if rate < obj.MIN_RATE
                rate = obj.MIN_RATE;
                disp('Minimum allowed flow rate exceeded');
            end
            
            fprintf(obj.handle, ['set rate ' num2str(rate)]);
            obj.rate = rate;
            
            % Read resulting parameters from pump. Pump outputs rate and
            % time
            fscanf(obj.handle); % Ignore first line
            
            result = fscanf(obj.handle);
            obj.rate = str2double(result(8:end-2));
            
            result = fscanf(obj.handle);
            obj.time = str2double(result(8:end-2));
            
            if obj.verbose
                disp(['Rate set to ' char(obj.mode) ' at ' num2str(rate) ' ' obj.unit_string]);
            end
        end
        
        % Set unit system for all parameters. 0=mL/min, 1=mL/hr, 2=uL/min,
        % 3=uL/hr
        function obj = set_units(obj,units)
            pause(0.5);
            fprintf(obj.handle, ['set units ' num2str(units)]);
            obj.units = units;
            
             % Read resulting parameters from pump. Pump outputs units.
            fscanf(obj.handle); % Ignore first line
            
            result = fscanf(obj.handle);
            obj.units = str2double(result(9:end-2));
            
            obj.update_parameters;
            if obj.verbose
                disp(['Units set to ' obj.unit_string]);
            end
        end
        
        % Set infusion/withdrawal volume. Positive volumes are for infusion
        % and negative volumes are for withdrawal. For unit systems 0 and
        % 1, units are mL. For unit systems 2 and 3, units are uL.
        function obj = set_volume(obj,volume)
            pause(0.5);
            fprintf(obj.handle, ['set volume ' num2str(volume)]);
            if volume < 0
                obj.mode = "withdrawal";
            else
                obj.mode = "infusion";
            end
            
            % Read resulting parameters from pump. Pump outputs volume,
            % rate, and time.
            fscanf(obj.handle); % Ignore first line
            result = fscanf(obj.handle);
            obj.volume = str2double(result(10:end-2));
            
            result = fscanf(obj.handle);
            obj.rate = str2double(result(8:end-2));
            
            result = fscanf(obj.handle);
            obj.time = str2double(result(8:end-2));
            
            if obj.verbose
                u_str = obj.unit_string;
                disp(['Volume set to ' num2str(volume) ' ' u_str(1:2)]);
            end
        end
        
        % Used to toggle between infusion and withdrawal mode. Function
        % will automatically detect current mode and switch to opposite
        function obj = toggle_mode(obj)
            if (obj.mode == "infusion")
                obj.mode = "withdrawal";
                obj.set_volume(-abs(obj.volume));
            else
                obj.mode = "infusion";
                obj.set_volume(abs(obj.volume));
            end
        end
        
        % Obtain a string describing unit system.
        function unit_str = unit_string(obj)
            switch obj.units
                case 0
                    unit_str = 'mL/min';
                case 1
                    unit_str = 'mL/hr';
                case 2
                    unit_str = 'uL/min';
                case 3
                    unit_str = 'uL/hr';
            end
        end
        
        % Read status of pump. 0=stopped, 1=running, 2=paused, 3=delayed,
        % 4=stalled
        function status = get_status(obj)
            pause(0.1);
            fprintf(obj.handle, 'status');
            fscanf(obj.handle); % Skip first line
            status = str2double(fscanf(obj.handle));
            if obj.verbose
                switch status
                    case 0
                        disp('Pump stopped.');
                    case 1
                        disp('Pump running.');
                    case 2
                        disp('Pump paused.');
                    case 3
                        disp('Pump delayed.');
                    case 4
                        disp('Pump stalled.');
                end
            end
        end
    end
end