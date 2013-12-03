function [data, time, abstime, events, daqinfo] = acquisitionHdf5read(filename,varargin)
%ACQUISITIONHDF5READ reads acquisition HDF5 file.
% [DATA, TIME, ABSTIME, EVENTS, DAQINFO] = ACQUISITIONHDF5READ(FILENAME, PROPERTY1, VALUE1, ...)
% Reads the acquisition HDF5 file FILENAME and returns the data in a matrix
% DATA (each row is an acquisition and each column is a channel) and
% optionally returns a vector of the sample times relative to the start
% trigger TIME, the absolute time of the start trigger as a ClockVec, a
% blank events structure EVENTS (here for compatability with daqread), and
% a daqinfo structure DAQINFO which has some of the properties that daqread
% would be able to give. Basically, this function works just like daqread
% does except EVENTS is not supported, DAQINFO doesn't have all fields, and
% some input arguments are not processed at all ('info', 'TimeFormat',
% 'OutputFormat', and 'Triggers'). The accepted property-value pairs are
%
% Samples : 2-element vector giving the range of samples to return. The
%   default is all. Mutually exclusive with the Time property.
%
% Time : 2-element vector giving the relative time range in seconds of
%   samples to return. The default is all. Mutually exclusive with the
%   Samples property.
%
% Channels : Vector of channel indices or cell array of channel names to
%   get the samples from.
%
% DataFormat : {'native','double','single','intXX','uintXX'} where XX can
%   be 8, 16, 32, or 64 (note, only 'native' and 'double' are supported by
%   daqread) giving the desired output datatype for DATA. 'native' denotes
%   that the native datatype of the data (/Data/Type in the hdf5 file)
%   should be used. {'double','single','intXX','uintXX'} denote that it
%   should be converted to the respective datatype. The data is not scaled
%   and offset for 'native'. The default is 'double'.

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

% Make an input parser for vargin and then process it go get all the
% optional arguments.

p = inputParser;

p.addOptional('Samples',NaN,@(x) numel(x) == 2 & all(isreal(x)) & x(1) <= x(2) & all(floor(x)==x) & x(1) >= 1);
p.addOptional('Time',NaN,@(x) numel(x) == 2 & all(isreal(x)) & x(1) <= x(2) & x(1) >= 0);
p.addOptional('Channels',NaN,@(x) true);
p.addOptional('DataFormat','double',@(x) any(strcmp(x, ...
            {'native','double','single', ...
            'uint8','uint16','uint32','uint64', ...
            'int8','int16','int32','int64'})));

p.parse(varargin{:});

% Stuff the arguments into parameters.

parameters = p.Results;

% As it is hard to check the format of the Channels parameter in the
% parameter checking above, it needs to be done more manually here.

if ~isnan(parameters.Channels)
    if iscell(parameters.Channels)
        for ii=1:numel(parameters.Channels)
            if ~isstr(parameters.Channels{ii})
                error('Channels is not in the right format.');
            elseif parameters.Channels{ii} == ''
                error('Channels names can''t be empty strings.');
            end
        end
    else
        if ~all(isreal(parameters.Channels)) ...
                        || ~all(floor(parameters.Channels)==parameters.Channels) ...
                        || ~all(parameters.Channels >= 1) ...
                        || numel(unique(parameters.Channels)) ~= numel(parameters.Channels)
            error('Channels is not in the right format.');
        end
    end
end

% Check to see if the file exists. If it doesn't, throw an error.

if ~exist(filename,'file')
    error(['File ',filename,' doesn''t exist.']);
end

% events is a dummy variable, so set it to empty.

events = [];

% Get the acquisition hdf5 file type and version and then check the type
% and see if it is right. If it isn't or an error is thrown, then it is the
% wrong format.

filetype = h5stringconvert(hdf5read(filename, '/Type'));
fileversion = h5stringconvert(hdf5read(filename, '/Version'));

if ~strcmpi(filetype,'Acquisition HDF5')
    error('Not an acquisition HDF5 file.');
end

% If the file is after version 1.0.0, it can't be read.

if 1 == versionCompare(fileversion,'1.0.0')
    error(['Cannot read file version ',fileversion,' > 1.0.0']);
end

% Get all the fields in /Info and make the daqinfo object.

daqinfo.HwInfo.VendorDriverDescription = h5stringconvert(hdf5read(filename,'/Info/VendorDriverDescription'));
daqinfo.HwInfo.DeviceName = h5stringconvert(hdf5read(filename,'/Info/DeviceName'));
daqinfo.HwInfo.ID = h5stringconvert(hdf5read(filename,'/Info/ID'));
daqinfo.ObjInfo.TriggerType = h5stringconvert(hdf5read(filename,'/Info/TriggerType'));
daqinfo.ObjInfo.InitialTriggerTime = hdf5read(filename,'/Info/StartTime')';
daqinfo.ObjInfo.SampleRate = hdf5read(filename,'/Info/SampleFrequency');
daqinfo.ObjInfo.InputType = h5stringconvert(hdf5read(filename,'/Info/InputType'));
daqinfo.HwInfo.Bits = double(hdf5read(filename,'/Info/Bits'));
daqinfo.ObjInfo.SamplesAcquired = double(hdf5read(filename,'/Info/NumberSamples'));

numberChannels = double(hdf5read(filename,'/Info/NumberChannels'));
channelMappings = double(hdf5read(filename,'/Info/ChannelMappings'));
channelNames = h5stringconvert(hdf5read(filename,'/Info/ChannelNames'));
channelInputRanges = hdf5read(filename,'/Info/ChannelInputRanges');
nativeOffsets = hdf5read(filename,'/Info/Offsets');
nativeScalings = hdf5read(filename,'/Info/Scalings');
units = h5stringconvert(hdf5read(filename,'/Info/Units'));

% Reconstruct daqinfo.ObjInfo.Channel.

for ii=1:numberChannels
    daqinfo.ObjInfo.Channel(ii).HwChannel = channelMappings(ii);
    daqinfo.ObjInfo.Channel(ii).ChannelName = channelNames{ii};
    daqinfo.ObjInfo.Channel(ii).InputRange = channelInputRanges(:,ii)';
    daqinfo.ObjInfo.Channel(ii).NativeOffset = nativeOffsets(ii);
    daqinfo.ObjInfo.Channel(ii).NativeScaling = nativeScalings(ii);
    daqinfo.ObjInfo.Channel(ii).Units = units{ii};
end

% Figure out what range of samples to do. NaN means do all.

sampleRange = [1 daqinfo.ObjInfo.SamplesAcquired];

if ~isnan(parameters.Samples)
    if parameters.Samples(1) > 1 || parameters.Samples(2) < daqinfo.ObjInfo.SamplesAcquired
        sampleRange = parameters.Samples;
    end
elseif ~isnan(parameters.Time)
    if parameters.Time(1) > 0 || parameters.Time(2)/daqinfo.ObjInfo.SampleRate < daqinfo.ObjInfo.SamplesAcquired
        sampleRange = parameters.Time*daqinfo.ObjInfo.SampleRate;
        sampleRange = 1+[ceil(sampleRange(1)) floor(sampleRange(2))];
        sampleRange(2) = max(sampleRange);
    end
end

if sampleRange(2) > daqinfo.ObjInfo.SamplesAcquired
    sampleRange(2) = daqinfo.ObjInfo.SamplesAcquired;
end

% Figure out which channels to read. NaN means do all.

channelsToRead = 1:numberChannels;

if ~isnan(parameters.Channels)
    if ~iscell(parameters.Channels)
        if any(parameters.Channels >  numberChannels)
            error('Can''t specify a channel out of range.');
        else
            channelsToRead = parameters.Channels;
        end
    else
        channelsToRead = [];
        for ii=1:numel(parameters.Channels)
            index = find(strcmp(parameters.Channels{ii},{daqinfo.ObjInfo.Channel.ChannelName}),1);
            if isempty(index)
                error('Channel not found.');
            else
                channelsToRead(ii) = index;
            end
        end
        if numel(unique(channelsToRead)) ~= numel(channelsToRead)
            error('Can''t read a channel twice.');
        end
    end
end

% Get the min and max channel numbers.

minChannel = min(channelsToRead);
maxChannel = max(channelsToRead);

% Construct time and abstime. abstime is just
% daqinfo.ObjInfo.InitialTriggerTime. time is pretty easy to make from
% the sample range and sample rate.

abstime = daqinfo.ObjInfo.InitialTriggerTime;
time = ((sampleRange(1):sampleRange(2))-1)'/daqinfo.ObjInfo.SampleRate;

% Get the native datatype of the data and the datatype used to store it.

datatype = h5stringconvert(hdf5read(filename,'/Data/Type'));
storagedatatype = h5stringconvert(hdf5read(filename,'/Data/StorageType'));

% If we are reading all samples and all channels, just grab the whole thing
% with hdf5read. If no samples were acquired, then we must return a row
% vector of zeros. Otherwise, we have to do a hyperslab read.

if daqinfo.ObjInfo.SamplesAcquired == 0
    data = zeros(1,numel(channelsToRead));
    time = 0;
elseif sampleRange(1) == 1 && sampleRange(2) == daqinfo.ObjInfo.SamplesAcquired ...
                && numel(channelsToRead) == numberChannels
    data = hdf5read(filename,'/Data/Data');
else

    % Open the file, dataset, and dataspace of the data.
    
    fileID = H5F.open(filename,'H5F_ACC_RDONLY','H5P_DEFAULT');  
    datasetID = H5D.open(fileID,'/Data/Data');
    dataspaceID = H5D.get_space(datasetID);
    
    % We need to make a non-default memory space to hold block that will be
    % gotten. It will hold all channels between min and max and the whole
    % sample range.
    
    memspaceID = H5S.create_simple(2, ...
                [1+sampleRange(2)-sampleRange(1) (1+maxChannel-minChannel)],[]);
            
    % Select the hyperslab of the data (only the channels between min and
    % max and the sample range).
            
    H5S.select_hyperslab(dataspaceID,'H5S_SELECT_SET', ...
                [(sampleRange(1)-1) (minChannel-1)], ...
                [1 1], ...
                [(1+sampleRange(2)-sampleRange(1)) (1+maxChannel-minChannel)], ...
                []);
    
    % We need to be able to convert matlab types to hdf5 types.

    hdf5Types = struct('single','H5T_NATIVE_FLOAT', ...
                        'double','H5T_NATIVE_DOUBLE', ...
                        'int8','H5T_NATIVE_INT8', ...
                        'int16','H5T_NATIVE_INT16', ...
                        'int32','H5T_NATIVE_INT32', ...
                        'int64','H5T_NATIVE_INT64', ...
                        'uint8','H5T_NATIVE_UINT8', ...
                        'uint16','H5T_NATIVE_UINT16', ...
                        'uint32','H5T_NATIVE_UINT32', ...
                        'uint64','H5T_NATIVE_UINT64');
                    
    % Read the data from the hyperslab of the data and convert it to the
    % right native data type.
                    
    data = H5D.read(datasetID,hdf5Types.(storagedatatype), ...
                memspaceID,dataspaceID,'H5P_DEFAULT');
            
    % Close everything.
    
    H5D.close(datasetID);
    H5S.close(memspaceID);
    H5S.close(dataspaceID);
    H5F.close(fileID);
    
end

% If only one time was read, then we read a row vector and we need to
% transpose it.

if numel(data) == channelsToRead(end)-minChannel+1
    data = data';
end

% Now, select the desired channels. The transpose is also done.

if numel(channelsToRead) > 1
    data = data(channelsToRead-minChannel+1,:)';
else
    % If it is a row vector, transpose it.
    if size(data,1) == 1
        data = data';
    end
end

% Convert the datatype to the native type.

if ~strcmp(datatype,storagedatatype)
    data = feval(datatype,data);
end

% If the target datatype (the DataFormat option) isn't native, then we have
% to convert the data type again and do the scaling and offset channel by
% channel.

if ~strcmpi(parameters.DataFormat,'native')
    
    data = feval(parameters.DataFormat,data);
    
    for ii=1:numel(channelsToRead)
        if nativeScalings(ii) ~= 1 || nativeOffsets(ii) ~= 0
            data(:,channelsToRead(ii)) = data(:,channelsToRead(ii))*nativeScalings(ii) + nativeOffsets(ii);
        end
    end
    
end
