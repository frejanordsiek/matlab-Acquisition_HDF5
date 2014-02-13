function aiHDF5startFunction(obj,event)
%AIHDF5STARTFUNCTION special function to handle the start event of acquisition to an HDF5 file.
% AIHDF5STARTFUNCTION( OBJ, EVENT)
% Function to handle the start event of an analog input object acquiring to
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

% Grab the UserData.

UserData = get(obj,'UserData');

% Make a daqinfo structure.

daqinfo = ai2daqinfo(obj);

% Create the hdf5 file with all but the correct trigger time and the /Data/
% group.

acquisitionHDF5create(obj.LogFileName,daqinfo);

% Now, write the datatype information to the /Data/ group.

hdf5write(obj.LogFileName,'/Data/Type',daqinfo.HwInfo.NativeDataType,'writemode','append');

if strcmpi(UserData.StorageDataType,'native')
    hdf5write(obj.LogFileName,'/Data/StorageType',daqinfo.HwInfo.NativeDataType,'writemode','append');
else
    hdf5write(obj.LogFileName,'/Data/StorageType',UserData.StorageDataType,'writemode','append');
end

% Create an empty data buffer with enough columns for every acquired
% channel. It will need to be the right datatype.

UserData.buffer = zeros(0,numel(daqinfo.ObjInfo.Channel),daqinfo.HwInfo.NativeDataType);

% As no blocks have been written yet, we should set the block count to
% zero.

UserData.ChunksWritten = 0;

% Now, the dataset to store the data in (/Data/Data) needs to be created
% and the handles stored in UserData.

% Open the HDF file.

UserData.handles.fileID = H5F.open(obj.LogFileName,'H5F_ACC_RDWR','H5P_DEFAULT');

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

% Get the appropriate hdf5 datatype for the storage.

if strcmpi(UserData.StorageDataType,'native')
    UserData.handles.datatypeID = H5T.copy(hdf5Types.(daqinfo.HwInfo.NativeDataType));
else
    UserData.handles.datatypeID = H5T.copy(hdf5Types.(UserData.StorageDataType));
end


% Create a dataspace for the data. It will initially have zero size but be
% able to grow in one direction.

UserData.handles.dataspaceID = H5S.create_simple(2, ...
            [1 numel(daqinfo.ObjInfo.Channel)],{'H5S_UNLIMITED',numel(daqinfo.ObjInfo.Channel)});

% Make a property list and set the chunk size (chunksize rows by number
% of channels columns) and to use compression at the specified level if we
% are doing compression

UserData.handles.plistID = H5P.create('H5P_DATASET_CREATE');
H5P.set_chunk(UserData.handles.plistID,[UserData.ChunkSize numel(daqinfo.ObjInfo.Channel)]);

if strcmpi(UserData.Compress,'yes')
    H5P.set_deflate(UserData.handles.plistID,UserData.CompressionLevel);
end

% Make the dataset.

UserData.handles.datasetID = H5D.create(UserData.handles.fileID, ...
            '/Data/Data', ...
            UserData.handles.datatypeID, ...
            UserData.handles.dataspaceID, ...
            UserData.handles.plistID);

% Done setting things up other than we need to write back UserData.

set(obj,'UserData',UserData);
