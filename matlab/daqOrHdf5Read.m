function [data, time, abstime, events, daqinfo] = daqOrHdf5Read(filename,varargin)
%DAQORHDF5READ reads daq file or acquisition HDF5 file, whichever is available.
% [DATA, TIME, ABSTIME, EVENTS, DAQINFO] = DAQORHDF5READ(FILENAME, PROPERTY1, VALUE1, ...)
% Reads the acquisition HDF5 file or daq file, whichever is available. See
% daqread.m and acquisitionHdf5Read.m for information on arguments and
% outputs. If FILENAME ends in .h5, the HDF5 file is read if available
% (reads the daq file if not). If FILENAME ends in .daq, the daq file is
% read if available (reads HDF5 file if not). If there is no extension, it
% is as if the extention was .h5 (reads HDF5 file if available and if not,
% reads daq file).

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

% Get file parts.

[pathstr, name, ext] = fileparts(filename);

% If no extension was given or it is something other than .h5 or .daq, set
% it to the default which is .h5.

if isempty(ext) || ~any(strcmpi(ext,{'.h5','.daq'}))
    ext = '.h5';
end

% Set the other/fallback extension.

if strcmpi(ext,'.h5')
    otherext = '.daq';
else
    otherext = '.h5';
end

% If the file exists, read it. If not, try the fallback. If neither are
% available, throw an error.

filename = fullfile(pathstr,[name, ext]);

if exist(filename,'file')
    if strcmpi(ext,'.h5')
        [data, time, abstime, events, daqinfo] = acquisitionHdf5read(filename,varargin{:});
    else
        [data, time, abstime, events, daqinfo] = daqread(filename,varargin{:});
    end
else
    filename = fullfile(pathstr,[name, otherext]);
    if exist(filename,'file')
        if strcmpi(otherext,'.h5')
            [data, time, abstime, events, daqinfo] = acquisitionHdf5read(filename,varargin{:});
        else
            [data, time, abstime, events, daqinfo] = daqread(filename,varargin{:});
        end
    else
        error('File not found.');
    end
end
