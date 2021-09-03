classdef HP33220A < handle
    properties
        address = 'GPIB1::10::1::INSTR';
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
        
        % Reset to defaults
        function reset(obj)
            fprintf(obj.handle,':PRES;');
        end
        
        function apply_square(obj,frequency,amplitude,offset)
            new_string = sprintf("APPL:SQU %f, %f, %f;",frequency,amplitude,offset);
            fprintf(obj.handle,new_string);
        end
        
        function apply_sin(obj,frequency,amplitude,offset)
            new_string = sprintf("APPL:SIN %f, %f, %f;",frequency,amplitude,offset);
            fprintf(obj.handle,new_string);
        end
        
        function output_off(obj)
            fprintf(obj.handle,'OUTP OFF;');
        end
        
        function output_on(obj)
            fprintf(obj.handle,'OUTP ON;');
        end

    end
end
