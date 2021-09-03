classdef HP3478A_Multimeter < handle
    properties
        address = 'GPIB0::23::1::INSTR';
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
        
        % Record number on screen
        function value = measure(obj)
            value = str2double(fscanf(obj.handle));
        end
        

    end
end