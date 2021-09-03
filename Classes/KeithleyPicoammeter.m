classdef KeithleyPicoammeter < handle
    properties
        address = 'GPIB0::22::1::INSTR';
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
        
        % Measure of the current
        function current = get_current(obj)
            result = fscanf(obj.handle);
            current = str2double(result(5:end));
        end
    end
end
