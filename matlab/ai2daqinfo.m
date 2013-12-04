function daqinfo = ai2daqinfo(ai)
%AI2DAQINFO makes a partial daqinfo structure from an analog input object.
% DAQINFO = AI2DAQINFO( AI) takes an analog input object AI and makes a
% partial daqinfo structure DAQINFO for use with acquistionHDF5create.m.

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

% The hardware info is easily gotten from daqhwinfo.

daqinfo.HwInfo = daqhwinfo(ai);

% Grab all but the Channel fields to make most of the ObjInfo fields.

daqinfo.ObjInfo.InitialTriggerTime = ai.InitialTriggerTime;
daqinfo.ObjInfo.InputType = ai.InputType;
daqinfo.ObjInfo.SampleRate = ai.SampleRate;
daqinfo.ObjInfo.SamplesAcquired = ai.SamplesAcquired;
daqinfo.ObjInfo.TriggerType = ai.TriggerType;

% The Channel fields have to be made by iteration. As using numel directly
% on ai.Channel just gives 1 regardless of the number of channels, we have
% to use a trick with get to find out how many channels there are.

for ii=1:numel(get(ai.Channel))
    daqinfo.ObjInfo.Channel(ii).ChannelName = ai.Channel(ii).ChannelName;
    daqinfo.ObjInfo.Channel(ii).HwChannel = ai.Channel(ii).HwChannel;
    daqinfo.ObjInfo.Channel(ii).InputRange = ai.Channel(ii).InputRange;
    daqinfo.ObjInfo.Channel(ii).NativeOffset = ai.Channel(ii).NativeOffset;
    daqinfo.ObjInfo.Channel(ii).NativeScaling = ai.Channel(ii).NativeScaling;
    daqinfo.ObjInfo.Channel(ii).Units = ai.Channel(ii).Units;
end
