function obj = aiHDF5WriteBuffer(obj,writemethod)
%AIHDF5WRITEBUFFER writes samples in the buffer to the hdf5 file. 
% AIHDF5WRITEBUFFER( OBJ, WRITEMETHOD)
% Given the analog input object OBJ that is acquiring to an acquisition
% HDF5 file, acquired samples in the buffer are written to the file.
% WRITEMETHOD specifies how this should be done. If it is 'chunks', then
% only whole chunks are written with the last samples that don't fit into a
% whole chunk left in the buffer. If it is 'full', then the whole buffer is
% written. The /Info/NumberSamples dataset in the file is updated to
% reflect how many samples have been written to the file. NOTE: this
% function is not meant to be called by the user, functions associated with
% acquiring to an acquisition HDF5 file (see makeAIsave2hdf5.m for more
% information).

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

% Grab the UserData.

UserData = get(obj,'UserData');

% Determine whether we have to write it out in full or not.

writefull = strcmpi(writemethod,'full');

% As long as the buffer is larger than the chunk size if writefull is false
% or if there is anything in the buffer at all if it is true, then we need
% to write a chunk. A flag will be used to indicate if any chunks were
% written at all (is needed in order to know if /Info/NumberSamples needs
% to be updated or not).

chunksWritten = false;

while (~writefull && size(UserData.buffer,1) >= UserData.ChunkSize) ...
                || (writefull && ~isempty(UserData.buffer))
            
    chunksWritten = true;
            
    % Grab the chunk to write and remove it from the buffer.
    
    if size(UserData.buffer,1) >= UserData.ChunkSize
        chunk = UserData.buffer(1:UserData.ChunkSize,:);
        UserData.buffer = UserData.buffer((UserData.ChunkSize+1):end,:);
    else
        chunk = UserData.buffer;
        UserData.buffer = zeros(0,size(chunk,2),class(chunk));
    end
    
    % Convert the datatype of the chunk if we are storing it with a
    % different datatype.
    
    if ~strcmpi(UserData.StorageDataType,'native')
        chunk = feval(UserData.StorageDataType,chunk);
    end
    
    % Grow the dataset to the proper size using how many full chunks have
    % been written and the size of the current chunk.
    
    H5D.extend(UserData.handles.datasetID, ...
                [(size(chunk,1) + UserData.ChunksWritten*UserData.ChunkSize) size(chunk,2)]);
    
    % Close the dataset handle and reget it (needed due to the extending).
    
    H5S.close(UserData.handles.dataspaceID);
    UserData.handles.dataspaceID = H5D.get_space(UserData.handles.datasetID);
    
    % Select the proper hyperslab to write the chunk.
    
    H5S.select_hyperslab(UserData.handles.dataspaceID,'H5S_SELECT_SET', ...
                [(UserData.ChunksWritten*UserData.ChunkSize) 0], ...
                [1 1], ...
                size(chunk), ...
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
                    
    % Create a memory space for chunk
    
    memorydatatypeID = H5T.copy(hdf5Types.(class(chunk)));
    memoryspaceID = H5S.create_simple(2,size(chunk),[]);
    
            
    % Write the data.
    
    H5D.write(UserData.handles.datasetID,...
                memorydatatypeID, ...
                memoryspaceID, ...
                UserData.handles.dataspaceID, ...
                'H5P_DEFAULT', ...
                chunk');
          
    % Close the memory space.
    
    H5S.close(memoryspaceID);
    H5T.close(memorydatatypeID);
    
    % Increase the written chunks count.
    
    UserData.ChunksWritten = UserData.ChunksWritten + 1;
    
end

% If any chunks were written to the file, /Info/NumberSamples needs to
% be updated.

if chunksWritten

    % Write out the number of samples that have been written to disk which is
    % the number of chunks-1 times the chunksize plus the size of the last
    % chunk written.

    datasetID = H5D.open(UserData.handles.fileID,'/Info/NumberSamples');

    H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT', ...
        int64((UserData.ChunksWritten-1)*UserData.ChunkSize + size(chunk,1)));

    H5D.close(datasetID);
    
end

% Set the UserData back.

set(obj,'UserData',UserData);
