function aiHDF5samplesAcquiredFunction(obj,event)
%AIHDF5SAMPLESACQUIREDFUNCTION special function to handle when a certain number of samples have been acquired when acquiring to an HDF5 file.
% AIHDF5STARTFUNCTION( OBJ, EVENT)
% Function to handle the SamplesAcquired event of an analog input object
% acquiring to an acquisition HDF5 file. This function is not meant to be
% called directly except as a callback in the analog input object. See
% makeAIsave2hdf5.m for more information.

% Copyright (c) 2013, Freja Nordsiek
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met
%
% 1. Redistributions of source code must retain the above copyright notice, this
% list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% Make a daqinfo structure.

daqinfo = ai2daqinfo(obj);

% Grab the UserData.

UserData = get(obj,'UserData');

% Grab the acquired data, if there is any. Otherwise set data to [];
        
if obj.SamplesAvailable > 0
    [data time] = getdata(obj, obj.SamplesAvailable,'native');
else
    data = zeros(0,numel(daqinfo.ObjInfo.Channel),daqinfo.HwInfo.NativeDataType);
    time = [];
end

% If we have any samples, then we should put them in the buffer and if
% there is enough in the buffer, write parts of it out.

if ~isempty(data)
    
    % Add the data to the buffer (append to the end).
    
    UserData.buffer = [UserData.buffer; data];
    
    % Set UserData back.
    
    set(obj,'UserData',UserData);
    
    % Write chunksize pieces of the buffer and keep the remainder.
    
    obj = aiHDF5WriteBuffer(obj,'chunks');
    
    % Grab the UserData.

    UserData = get(obj,'UserData');
    
end

% Set UserData back.

set(obj,'UserData',UserData);

% Call the usersupplied SamplesAcquiredFunction if available giving it the
% acquired data.

if ~isempty(UserData.SamplesAcquiredFcn)
    UserData.SamplesAcquiredFcn(obj,event,data,time);
end
