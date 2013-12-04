function acquisitionHDF5create(hdf5filename,daqinfo)
%ACQUISITIONHDF5CREATE creates an acquisition HDF5 (all the header and info stuff).
% ACQUISITIONHDF5CREATE( HDF5FILENAME, DAQINFO) creates an acquisition HDF5
% file HDF5FILENAME with the daqinfo information in DAQINFO. Creates
% everything but the /Data group (/Type, /Version, and the whole /Info/
% group).

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

% Create the file, write the type of file, and append the version
% information.

hdf5write(hdf5filename, '/Type','Acquisition HDF5');
hdf5write(hdf5filename, '/Version','1.0.0','writemode','append');

% Write the Info fields. The group doesn't have to be explicitly created as
% matlab will do that if the group doesn't exist yet.

hdf5write(hdf5filename,'/Info/VendorDriverDescription',daqinfo.HwInfo.VendorDriverDescription,'writemode','append');
hdf5write(hdf5filename,'/Info/DeviceName',daqinfo.HwInfo.DeviceName,'writemode','append');
hdf5write(hdf5filename,'/Info/ID',daqinfo.HwInfo.ID,'writemode','append');
hdf5write(hdf5filename,'/Info/TriggerType',daqinfo.ObjInfo.TriggerType,'writemode','append');
hdf5write(hdf5filename,'/Info/StartTime',daqinfo.ObjInfo.InitialTriggerTime,'writemode','append');
hdf5write(hdf5filename,'/Info/SampleFrequency',daqinfo.ObjInfo.SampleRate,'writemode','append');
hdf5write(hdf5filename,'/Info/InputType',daqinfo.ObjInfo.InputType,'writemode','append');
hdf5write(hdf5filename,'/Info/NumberChannels',int64(numel(daqinfo.ObjInfo.Channel)),'writemode','append');
hdf5write(hdf5filename,'/Info/Bits',int64(daqinfo.HwInfo.Bits),'writemode','append');
hdf5write(hdf5filename,'/Info/NumberSamples',int64(daqinfo.ObjInfo.SamplesAcquired),'writemode','append');
hdf5write(hdf5filename,'/Info/ChannelMappings',int64([daqinfo.ObjInfo.Channel.HwChannel]),'writemode','append');
hdf5write(hdf5filename,'/Info/ChannelNames',{daqinfo.ObjInfo.Channel.ChannelName},'writemode','append');
hdf5write(hdf5filename,'/Info/ChannelInputRanges', ...
    reshape([daqinfo.ObjInfo.Channel.InputRange],2,numel(daqinfo.ObjInfo.Channel)),'writemode','append');
hdf5write(hdf5filename,'/Info/Offsets',double([daqinfo.ObjInfo.Channel.NativeOffset]),'writemode','append');
hdf5write(hdf5filename,'/Info/Scalings',double([daqinfo.ObjInfo.Channel.NativeScaling]),'writemode','append');
hdf5write(hdf5filename,'/Info/Units',{daqinfo.ObjInfo.Channel.Units},'writemode','append');
