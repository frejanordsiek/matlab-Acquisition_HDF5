function cmp = versionCompare(version1,version2)
%VERSIONCOMPARE compares two versions.
% CMP = VERSIONCOMPARE( VERSION1, VERSION2)
%
% Compares the two versions VERSION1 and VERSION2 (each can either be a
% vector of version fields or a version string with fields separated by '.'
% or ' ' characters. The result is +1 if VERSION1 > VERSION2, 0 if they are
% the same, and -1 if VERSION1 < VERSION2.

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

% If the arguments are version strings, they need to be extracted.

if ischar(version1)
    version1(version1 == '.') = ' ';
    version1 = sscanf(version1,'%u');
end

if ischar(version2)
    version2(version2 == '.') = ' ';
    version2 = sscanf(version2,'%u');
end

% Compare each field they have in common, returning the result of the first
% comparison of fields that are not equal.

for ii=1:min(numel(version1),numel(version2))
    cmp = sign(version1(ii)-version2(ii));
    if cmp ~= 0
        return;
    end
end

% If one has more fields than the other, it is the newer one unless the
% extra fields are all zero. If they have the same number of fields, they
% are the same because the previous loop would have returned otherwise.

switch sign(numel(version1) - numel(version2))
    case 1
        cmp = double(~all(version1((numel(version2)+1):end) == 0));
    case -1
        cmp = -double(~all(version2((numel(version1)+1):end) == 0));
    case 0
        cmp = 0;
end
    