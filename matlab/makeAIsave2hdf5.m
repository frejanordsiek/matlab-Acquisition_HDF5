function ai = makeAIsave2hdf5(ai,SamplesAcquiredFcn,varargin)
%MAKEAISAVE2HDF5 makes an analog input object acquire to an HDF5 file.
% AI = MAKEAISAVE2HDF5( AI, SAMPLESACQUIREDFCN, PROPERTY1, VALUE1, ...)
% Makes the analog input object AI so that it acquires to the acquisition
% HDF5 file (see daq2hdf5.m for its internal structure) specified in the
% AI.LogFileName. SAMPLESACQUIREDFCN is a function handle (set to empty to
% designate nothing) that is called when AI.SamplesAcquiredFcn would
% normally be called if the analog input was acquiring to a .daq file. It
% can be changed later by changing AI.UserData.SamplesAcquiredFcn. It must
% be a function of the form f(obj,event,data,times) where obj and event
% are just like they are for normal analog input object (the analog input
% object and the events list) and data and times are the data that was
% acquired since the last time the designated number of samples was
% acquired and times is the times of samples relative to the trigger. Do
% NOT fiddle with the Start, Stop, Trigger, and SamplesAcquired callbacks
% in AI while the analog input is acquiring. After it is done, though, they
% MUST be cleared. The following roperty-value pairs, which control the
% acquisition to disk, are accepted.
%
% ChunkSize: Integer specifying the number of acquisition samples (all
%   all channels) to group together when storing the data in the file. The
%   default is 1024.
%
% StorageDataType: {'native','single','double','uintXX','intXX'} where XX
%   is 8, 16, 32, or 64. Specifies which matlab data type to convert the
%   acquired data to. The default 'native' is used to indicate no
%   conversion.
%
% Compress: {'yes','no'} Whether or not to compress the acquired data (uses
%   deflate algorithm, which is what gzip uses). The default is 'yes'.
%
% CompressionLevel: 0-9 Integer compression level to do data compression
%   with if it is being done. 0 denotes little compression and 9 denotes
%   maximum compression. The default is 7.

% Copyright (c) 2013, Freja Nordsiek
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without modification,
% are permitted provided that the following conditions are met:
% 
%   Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
%   Redistributions in binary form must reproduce the above copyright notice, this
%   list of conditions and the following disclaimer in the documentation and/or
%   other materials provided with the distribution.
% 
%   Neither the name of the {organization} nor the names of its
%   contributors may be used to endorse or promote products derived from
%   this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% Have to do more manual input processing since this needs to run on older
% versions of MATLAB that don't have inputParser.

% % Make an input parser for vargin and then process it go get all the
% % optional arguments.
% 
% p = inputParser;
% 
% p.addOptional('StorageDataType','native',@(x) any(strcmp(x, ...
%             {'native','double','single', ...
%             'uint8','uint16','uint32','uint64', ...
%             'int8','int16','int32','int64'})));
% p.addOptional('Compress','yes',@(x) any(strcmpi(x,{'yes','no',})));
% p.addOptional('CompressionLevel',7,@(x) isreal(x) & numel(x) == 1 & x >= 0 & x <= 9 & floor(x) == x);
% p.addOptional('ChunkSize',1024,@(x) isreal(x) & numel(x) == 1 & x >= 1 & floor(x) == x);
% 
% p.parse(varargin{:});
% 
% % Stuff the arguments into parameters.
% 
% parameters = p.Results;

% Since there are only 4 pairs of input arguement property-value pairs,
% there must either be 0, 2, 4, ... , 8 arguments or else there is an
% error.

if ~any(numel(varargin) == 0:2:8)
    error('Input error (wrong number of arguments.');
end

% Set the defaults.

parameters.ChunkSize = 1024;
parameters.StorageDataType = 'native';
parameters.Compress = 'yes';
parameters.CompressionLevel = 7;

% Go through each pair of input arguments (property-value pair) and process
% them.

for pair = 1:round(numel(varargin)/2)
    
    % Extract the property and the value.
    
    property = varargin{2*pair - 1};
    value = varargin{2*pair};
    
    % Figure out which property is being set and then handle the value
    % accordingly.
    
    switch property
        case 'ChunkSize'
            if ~isreal(value) || numel(value) ~= 1 || value < 1 || floor(value) ~= value
                error('ChunkSize must be a positive integer.');
            end
            parameters.ChunkSize = value;
        case 'StorageDataType'
            if ~ischar(value) || ~any(strcmp(value,{'native','double','single', ...
                    'uint8','uint16','uint32','uint64', ...
                    'int8','int16','int32','int64'}))
                error('Invalid StorageDataType');
            end
            parameters.StorageDataType = value;
        case 'Compress'
            if ~ischar(value) || ~any(strcmp(value,{'yes','no'}))
                error('Compress must be either ''yes'' or ''no''');
            end
            parameters.Compress = value;
        case 'CompressionLevel'
            if ~isreal(value) || numel(value) ~= 1 || value < 0 || value > 9 || floor(value) ~= value
                error('CompressionLevel must be an integer between 0 and 9 inclusive.');
            end
            parameters.CompressionLevel = value;
        otherwise
            error('Unsupported Property-Value pair.');
    end
    
end

% Set the ai to logging to memory since we are handling the saving to disk
% manually.

ai.LoggingMode = 'Memory';

% Set the ai callback functions to the proper acquistion hdf5 functions.

ai.SamplesAcquiredFcn = @aiHDF5samplesAcquiredFunction;
ai.TriggerFcn = @aiHDF5triggerFunction;
ai.StartFcn = @aiHDF5startFunction;
ai.StopFcn = @aiHDF5stopFunction;

% Now, in UserData, we will have fields for the callback that the user
% wants called when the specified number of samples is acquired and the
% different acquisition properties.

UserData.SamplesAcquiredFcn = SamplesAcquiredFcn;
UserData.StorageDataType = parameters.StorageDataType;
UserData.Compress = parameters.Compress;
UserData.CompressionLevel = parameters.CompressionLevel;
UserData.ChunkSize = parameters.ChunkSize;

set(ai,'UserData',UserData);

% Everything is setup.
