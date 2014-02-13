function aiHDF5triggerFunction(obj,event)
%AIHDF5STARTFUNCTION special function to handle the trigger event of acquisition to an HDF5 file.
% AIHDF5STARTFUNCTION( OBJ, EVENT)
% Function to handle the trigger event of an analog input object acquiring to
% an acquisition HDF5 file. This function is not meant to be called
% directly except as a callback in the analog input object. See
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

% Write out the start time of the trigger.

datasetID = H5D.open(UserData.handles.fileID,'/Info/StartTime');

H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',daqinfo.ObjInfo.InitialTriggerTime);

H5D.close(datasetID);

% Set UserData back.

set(obj,'UserData',UserData);
