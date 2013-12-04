function aiHDF5stopFunction(obj,event)
%AIHDF5STARTFUNCTION special function to handle the stop event of acquisition to an HDF5 file.
% AIHDF5STARTFUNCTION( OBJ, EVENT)
% Function to handle the stop event of an analog input object acquiring to
% an acquisition HDF5 file. This function is not meant to be called
% directly except as a callback in the analog input object. See
% makeAIsave2hdf5.m for more information.

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

% Make a daqinfo structure.

daqinfo = ai2daqinfo(obj);

% Grab the UserData.

UserData = get(obj,'UserData');

% Grab any remaining data.
        
if obj.SamplesAvailable > 0
    data = getdata(obj, obj.SamplesAvailable,'native');
else
    data = zeros(0,numel(daqinfo.ObjInfo.Channel),daqinfo.HwInfo.NativeDataType);
end

% Add data to the buffer.

UserData.buffer = [UserData.buffer; data];

% Set UserData back.

set(obj,'UserData',UserData);
    
% Write whatever is left in the buffer.

obj = aiHDF5WriteBuffer(obj,'full');

% Grab the UserData.

UserData = get(obj,'UserData');

% Close all the hdf5 file handles since all is done.

H5D.close(UserData.handles.datasetID);
H5P.close(UserData.handles.plistID);
H5S.close(UserData.handles.dataspaceID);
H5T.close(UserData.handles.datatypeID);
H5F.close(UserData.handles.fileID);

% Set UserData back.

set(obj,'UserData',UserData);

