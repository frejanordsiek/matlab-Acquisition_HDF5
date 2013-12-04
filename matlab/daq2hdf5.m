function daq2hdf5(daqfilename,hdf5filename,varargin)
%DAQ2HDF5 converts a .daq file to an acquisition HDF5 file.
% DAQ2HDF5( DAQFILENAME, HDF5FILENAME, ... , 'Property',Value, ...)
% Converts the .daq file named DAQFILE (this is the type of file that the
% Data Acquisition Toolbox saves to) to an acquisition HDF5 file format
% named HDF5FILENAME. The optional options are
%
% ChunkSize: Integer specifying the number of acquisition samples (all
%   all channels) to group together when storing the data in the file. The
%   default is 1024.
%
% ConvertDataType: {'no','single','double','uintXX','intXX'} where XX is 8,
%   16, 32, or 64. Specifies which matlab data type to convert the acquired
%   data to. The default 'no' is used to indicate no conversion.
%
% Compress: {'yes','no'} Whether or not to compress the acquired data (uses
%   deflate algorithm, which is what gzip uses). The default is 'yes'.
%
% CompressionLevel: 0-9 Integer compression level to do data compression
%   with if it is being done. 0 denotes little compression and 9 denotes
%   maximum compression. The default is 7.
%
%
%
% The acquisition HDF5 file format is as follows.
%
% /Type : String telling the type of file this is ('Acquisition HDF5').
%
% /Version : Version string of the file format.
%
% /Info/VendorDriverDescription : String indicating the hardware vendor and
%   driver. Corresponds to daqinfo.HwInfo.VendorDriverDescription.
%
% /Info/DeviceName : String name of the DAQ device (model). Corresponds to
%   daqinfo.HwInfo.DeviceName.
%
% /Info/ID : String ID of the DAQ device (which one if more than one is
%   connected). Corresponds to daqinfo.HwInfo.ID.
%
% /Info/TriggerType : String indicating the type of trigger that started
%   the acquisition ('immediate','HwDigital',etc.). Corresponds to
%   daqinfo.ObjInfo.TriggerType.
% /Info/StartTime : Clockvec (vector of 6 doubles in year, month, day,
%   hour, minute, second order) indicating when acquisition started (was
%   triggered). Corresponds to daqinfo.ObjInfo.InitialTriggerTime.
%
% /Info/SampleFrequency : Double indicatng the sampe frequency in Hz.
%   Corresponds to daqinfo.ObjInfo.SampleRate.
%
% /Info/InputType : String indicating what type of inputs were measured
%   ('Differential','SingleEnded',etc.). Corresponds to
%   daqinfo.ObjInfo.InputType.
%
% /Info/NumberChannels : int64 indicating the number of channels acquired.
%
% /Info/Bits : int64 indicating the number of bits the ADC read.
% Corresponds to daqinfo.HwInfo.Bits.
%
% /Info/NumberSamples : int64 indicating how many samples were acquired
%   during acquisition. Corresponds to daqinfo.ObjInfo.SamplesAcquired.
%
% /Info/ChannelMappings : int64 array indicating which hardware channel
%   each channel corresponded to. Corresponds to
%   daqinfo.ObjInfo.Channel(:).HwChannel.
%
% /Info/ChannelNames : Array of strings indicating the names of each
%   channel. Corresponds to daqinfo.ObjInfo.Channel(:).ChannelName.

% /Info/ChannelInputRanges : Array of doubles indicating the input ranges
%   for each channel. Each row is a channel with two columns that are the
%   minimum and maximum of the range. Corresponds to
%   daqinfo.ObjInfo.Channel(:).InputRange.
%
% /Info/Offsets : Double array indicating the offset to add to each channel
%   when reading it back. data = scaling*rawdata + offset. Corresponds to
%   daqinfo.ObjInfo.Channel(:).NativeOffset.
%
% /Info/Scalings : Double array indicating the scaling factor to multiply
%   each channel by when reading it back. data = scaling*rawdata + offset.
%   Corresponds to Corresponds to daqinfo.ObjInfo.Channel(:).NativeScaling.
%
% /Info/Units : String array indicating the units for each channel.
%   Corresponds to daqinfo.ObjInfo.Channel(:).Units.
%
% /Data/Type : String indicating the data type to convert to when
%   extracting the data. Is one of the set {'single','double','uintXX',
%   'intXX'} where XX is 8, 16, 32, or 64.
%
% /Data/StorageType : String indicating the data type used to store the
%   data with. Is one of the set {'single','double','uintXX', 'intXX'}
%   where XX is 8, 16, 32, or 64.
%
% /Data/Data : Array of the specified storage type (what is in the daqfile
%   or what it is to be converted to if given that option) that is
%   NumberSamples X NumberChannels. May be chuncked and compressed with the
%   deflate algorithm.

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

p.addOptional('ConvertDataType','no',@(x) any(strcmp(x, ...
            {'no','double','single', ...
            'uint8','uint16','uint32','uint64', ...
            'int8','int16','int32','int64'})));
p.addOptional('Compress','yes',@(x) any(strcmpi(x,{'yes','no',})));
p.addOptional('CompressionLevel',7,@(x) isreal(x) & numel(x) == 1 & x >= 0 & x <= 9 & floor(x) == x);
p.addOptional('ChunkSize',1024,@(x) isreal(x) & numel(x) == 1 & x >= 1 & floor(x) == x);

p.parse(varargin{:});

% Stuff the arguments into parameters.

parameters = p.Results;

% First, read all the data from the daqfile and then we can work out
% writing it to HDF5. It will be done in native format which will be
% unscaled.

[data, time, abstime, events, daqinfo] = daqread(daqfilename,'DataFormat','native');

% Create the acquisition HDF5 (set the /Type, /Version, and all the /Info/
% datasets).

acquisitionHDF5create(hdf5filename,daqinfo);

% Write the original data type and the storage data type.

hdf5write(hdf5filename,'/Data/Type',class(data),'writemode','append');

if any(strcmpi(parameters.ConvertDataType,{'no',class(data)}))
    hdf5write(hdf5filename,'/Data/StorageType',class(data),'writemode','append');
else
    hdf5write(hdf5filename,'/Data/StorageType',parameters.ConvertDataType,'writemode','append');
end

% Do data type conversion if asked. Luckily, the parameter value is the
% function needed to actually do the conversion.

if ~any(strcmpi(parameters.ConvertDataType,{'no',class(data)}))
    data = feval(parameters.ConvertDataType,data);
end

% Now it is time to write the data. Since we will be doing chunking and
% optionally compression, this must be done more manually than simply using
% the hdf5write function.
    
% If the given chunk size is larger than the number of acquisitions
% (rows of data), we will set the chunk size to be the number of
% acquisitions.

parameters.ChunkSize = min(parameters.ChunkSize,size(data,1));

% Now, to get to saving the data. We first need to open the hdf5 file
% and then open the group.

fileID = H5F.open(hdf5filename,'H5F_ACC_RDWR','H5P_DEFAULT');
groupID = H5G.open(fileID,'/Data');

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

% Get the appropriate hdf5 datatype.

datatypeID = H5T.copy(hdf5Types.(class(data)));

% Create a dataspace of the size to fit data.

dataspaceID = H5S.create_simple(2, size(data), []);

% Make a property list and set the chunk size (chunksize rows by number
% of channels columns) and to use compression at the specified level if we
% are doing compression

plistID = H5P.create('H5P_DATASET_CREATE');
H5P.set_chunk(plistID,[parameters.ChunkSize size(data,2)]);

if strcmpi(parameters.Compress,'yes')
    H5P.set_deflate(plistID,parameters.CompressionLevel);
end

% Make the dataset.

datasetID = H5D.create(groupID,'Data', datatypeID, dataspaceID, plistID);

% Now, write the data

H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',data');

% Close all the handles to finish up

H5D.close(datasetID);
H5P.close(plistID);
H5S.close(dataspaceID);
H5T.close(datatypeID);
H5G.close(groupID);
H5F.close(fileID);
