classdef SR844_LockIn < handle
    properties
        address = 'GPIB0::1::1::INSTR';
        handle;
    end
    methods
        % Define object handle and open connection.
        function obj = open(obj)
            obj.handle = visa('ni',obj.address);
            fopen(obj.handle);
        end
        
        % Close connection
        function close(obj)
            fclose(obj.handle);
        end
        
        function real_part = read_real(obj)
            fprintf(obj.handle,"OUTP?1;");
            real_part = str2double(fscanf(obj.handle));
        end
        
        function imaginary_part = read_imaginary(obj)
            fprintf(obj.handle,"OUTP?2;");
            imaginary_part = str2double(fscanf(obj.handle));
        end
        
        function magnitude = read_magnitude(obj)
            fprintf(obj.handle,"OUTP?3;");
            magnitude = str2double(fscanf(obj.handle));
        end
        
        function phase = read_phase(obj)
            fprintf(obj.handle,"OUTP?4;");
            phase = str2double(fscanf(obj.handle));
        end
        
        function set_frequency(obj,frequency,silent)
            fprintf(obj.handle,"FREQ %d;",frequency);
            if ~silent
                fprintf("Frequency set to %0.6f MHz.\n",obj.read_frequency/1e6)
            end
        end
        
        function frequency = read_frequency(obj)
            fprintf(obj.handle,"FREQ?;");
            frequency = str2double(fscanf(obj.handle));
        end
        
        function set_sens(obj,value)
            % Values:
            % 0: 100 nV     8:  1 mV
            % 1: 300 nV     9:  3 mV
            % 2: 1 uV       10: 10 mV
            % 3: 3 uV       11: 30 mV
            % 4: 10 uV      12: 100 mV
            % 5: 30 uV      13: 300 mV
            % 6: 100 uV     14: 1 V
            % 7: 300 uV
            fprintf(obj.handle,"SENS %d;",value);
        end
        
        function sensitivity = read_sens(obj)
            fprintf(obj.handle,"SENS?;");
            sensitivity = str2double(fscanf(obj.handle));
            sens=[100e-9 300e-9 1e-6 3e-6 10e-6 30e-6 100e-6 300e-6 1e-3 3e-3 10e-3 30e-3 100e-3 300e-3 1];
            disp(['Sensitivity: ' num2str(sens(sensitivity+1)) ' V']);
            sensitivity = [sensitivity sens(sensitivity+1)];

        end

        function set_time_const(obj,value)
            % Values: 
            % 0 = 100 us
            % 1 = 300 us
            % 2 = 1 ms
            % 3 = 3 ms
            % 4 = 10 ms
            % 5 = 30 ms
            fprintf(obj.handle,"OFLT %d;",value);
        end
        
        function time_constant = read_time_const(obj)
            fprintf(obj.handle,"OFLT?;");
            time_constant = str2num(fscanf(obj.handle));
            constants = [100e-6 300e-6 1e-3 3e-3 10e-3 30e-3 100e-3 300e-3 1 3 10 30 100 300 1000 3000 10000 30000];
            disp(['Time constant: ' num2str(constants(time_constant+1)) ' seconds'])
            time_constant = [time_constant constants(time_constant+1)];
        end
        
        function set_harmonic(obj,harmonic)
            % harmonic = 1 = measure at F
            % harmonic = 2 = measure at 2F
            fprintf(obj.handle,"HARM %d;",harmonic-1);
            obj.read_harmonic;
        end
        
        function harmonic = read_harmonic(obj)
            fprintf(obj.handle,"HARM?;");
            harmonic = fscanf(obj.handle);
            disp(['Measuring at ' num2str(str2num(harmonic)+1) 'F']);
        end
        
        function set_reference_mode(obj,ref_mode)
            % mode = 0: External
            % mode = 1: Internal
            modes = ["External"; "Internal"];
            fprintf(obj.handle,"FMOD %d;",ref_mode);
            disp(strcat(modes(ref_mode+1)," reference mode set."))
        end
    end
end