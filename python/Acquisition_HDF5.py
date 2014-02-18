# Copyright (c) 2014, Freja Nordsiek
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

""" Module for reading/writing Acquisition HDF5 files.

Version 0.1

"""

__version__ = "0.1"


import sys
import platform
from distutils.version import LooseVersion

import numpy as np
import h5py

import hdf5storage


# Make a lookup of numpy types by data type value.
_data_types = {'uint8': np.uint8,
               'uint16': np.uint16,
               'uint32': np.uint32,
               'uint64': np.uint64,
               'int8': np.int8,
               'int16': np.int16,
               'int32': np.int32,
               'int64': np.int64,
               'single': np.float32,
               'double': np.float64}


def _get_supported_version(version):
    # Find the supported version it matches and return the type string
    # of the one it matches. Otherwise return None.
    loose_version = LooseVersion(version)
    # First, we need a LooseVersion lists of all versions that one might
    # see out there that are currently supported. Then, everything
    # between 0.0.1 and 1.0.0 is the same as 1.0.0.
    versions_supported = ['0.0.1', '1.0.0', '1.1.0']
    lvs = [LooseVersion(v) for v in versions_supported]

    if LooseVersion('0.0.1') <= loose_version \
            and LooseVersion('1.0.0') >= loose_version:
        return '1.0.0'

    index = lvs.index(loose_version)
    if index != -1:
        return versions_supported[index]
    else:
        return None


def _convert_to_numpy_bytes(s):
    if isinstance(s, np.bytes_):
        return s
    elif isinstance(s, bytes):
        return np.bytes_(s)
    else:
        return np.bytes_(s.encode())


class Writer(object):
    def __init__(self, filename,
                 Version='1.1.0',
                 data_type='double',
                 data_storage_type='single',
                 compression='gzip',
                 compression_opts=9,
                 shuffle=True,
                 fletcher32=True,
                 chunks=(1024, None),
                 Info=dict(),
                 **keywords):
        # Set this first before anything else so that nothing goes wrong
        # on deletion.
        self._file = None

        # Check that the Version is valid, and get the Version string we
        # will be using.
        if not isinstance(Version, str):
            raise ValueError('Version must be a bytes.')

        new_version = _get_supported_version(Version).encode()
        if new_version is None:
            raise ValueError('Unsupported Version.')

        # First, if any additional keyword arguments were given, they
        # need to be stuffed into Info.
        for k, v in keywords.items():
            Info[k] = v

        # Validate inputs.

        # All the simple arguments must be the right type, and that the
        # right things are there.

        if type(Version) != str \
                or type(data_type) != str \
                or type(data_storage_type) != str:
            raise ValueError('At least one input arguments is not of '
                             + 'right type.')

        # Various parameters in info that need to be checked. In each
        # tuple, the first element is the name, the second is a buple of
        # types it must be one of, and the third is a default value to
        # give if present (if no default value is present, the parameter
        # is required to be given). Also, all string types need to be
        # converted to numpy bytes_.

        if sys.hexversion >= 0x03000000:
            string_types = (str, bytes, np.bytes_, np.str_)
        else:
            string_types = (unicode, str, np.bytes_, np.unicode_)

        params = [ \
            ('VendorDriverDescription', string_types, b''), \
            ('DeviceName', string_types, b''), \
            ('ID', string_types, b''), \
            ('TriggerType', string_types, b''), \
            ('SampleFrequency', (np.float64,)), \
            ('InputType', string_types, b''), \
            ('NumberChannels', (np.int64,)), \
            ('Bits', (np.int64,), np.int64(-1)), \
            ('ChannelMappings', (np.ndarray, type(None)), None), \
            ('ChannelNames', (np.ndarray, type(None)), None), \
            ('ChannelInputRanges', (np.ndarray, type(None)), None), \
            ('Offsets', (np.ndarray, type(None)), None), \
            ('Scalings', (np.ndarray, type(None)), None), \
            ('Units', (np.ndarray, type(None)), None)]

        for param in params:
            if param[0] in Info:
                if not isinstance(Info[param[0]], param[1]):
                    raise ValueError("Info['" + param[0] + "'] is "
                                     + 'not the right type.')
            elif len(param) > 2:
                Info[param[0]] = param[2]
            else:
                raise ValueError("Info is missing field '"
                                 + param[0] + "'.")
            if param[1] == string_types:
                Info[param[0]] = _convert_to_numpy_bytes(Info[param[0]])

        # Check that we have a positive number of channels.
        if Info['NumberChannels'] < 1:
            raise ValueError('There must be at least one channel.')

        # If the channel mappings aren't given, make it the default
        # (incrementing integers from 0). If it is given, check it.
        if Info['ChannelMappings'] is None:
            Info['ChannelMappings'] = np.int64( \
                np.r_[0:Info['NumberChannels']])
        elif type(Info['ChannelMappings']) != np.ndarray \
                or Info['ChannelMappings'].dtype.name != 'int64' \
                or Info['ChannelMappings'].shape \
                != (Info['NumberChannels'], ):
            raise ValueError('ChannelMappings isn''t a numpy.int64 '
                             + 'row array with an element for each '
                             + 'channel.')

        # If the channel names aren't given, make it the default (all
        # b''). If it is given, check it.
        if Info['ChannelNames'] is None:
            Info['ChannelNames'] = \
                np.zeros(shape=(Info['NumberChannels'], ), \
                dtype='bytes')
        elif type(Info['ChannelNames']) != np.ndarray \
                or not Info['ChannelNames'].dtype.name.startswith( \
                'bytes') \
                or Info['ChannelNames'].shape \
                != (Info['NumberChannels'], ):
            raise ValueError('ChannelNames isn''t a numpy.bytes_ '
                             + 'row array with an element for each '
                             + 'channel.')

        # If the channel input ranges aren't given, make it the default
        # (array from zeros). If it is given, check it.
        if Info['ChannelInputRanges'] is None:
            Info['ChannelInputRanges'] = np.zeros(\
                shape=(Info['NumberChannels'], 2), dtype='float64')
        elif type(Info['ChannelInputRanges']) != np.ndarray \
                or Info['ChannelInputRanges'].dtype.name != 'float64' \
                or Info['ChannelInputRanges'].shape \
                != (Info['NumberChannels'], 2):
            raise ValueError('ChannelInputRanges isn''t a numpy '
                             + 'float64 array with 2 columns and a ' \
                             + 'row for each channel.')

        # If the Offsets aren't given, make it the default (row of
        # zeros). If it is given, check it.
        if Info['Offsets'] is None:
            Info['Offsets'] = np.zeros( \
                shape=(Info['NumberChannels'],), dtype='float64')
        elif type(Info['Offsets']) != np.ndarray \
                or Info['Offsets'].dtype.name != 'float64' \
                or Info['Offsets'].shape \
                != (Info['NumberChannels'], ):
            raise ValueError('Offsets isn''t a numpy.float64 '
                             + 'row array with an element for each '
                             + 'channel.')

        # If the Scalings aren't given, make it the default (row of
        # ones). If it is given, check it.
        if Info['Scalings'] is None:
            Info['Scalings'] = np.ones(shape=(Info['NumberChannels'],),
                                       dtype='float64')
        elif type(Info['Scalings']) != np.ndarray \
                or Info['Scalings'].dtype.name != 'float64' \
                or Info['Scalings'].shape != (Info['NumberChannels'], ):
            raise ValueError('Scalings isn''t a numpy.float64 '
                             + 'row array with an element for each '
                             + 'channel.')

        # If the Units aren't given, make it the default (all b''). If
        # it is given, check it.
        if Info['Units'] is None:
            Info['Units'] = np.zeros(shape=(Info['NumberChannels'], ),
                                     dtype='bytes')
        elif type(Info['Units']) != np.ndarray \
                or not Info['Units'].dtype.name.startswith('bytes') \
                or Info['Units'].shape != (Info['NumberChannels'], ):
            raise ValueError('Units isn''t a numpy.bytes_ '
                             + 'row array with an element for each '
                             + 'channel.')

        # data_type and data_storage_types must be in the lookup.
        if data_type not in _data_types:
            raise ValueError('data_type must be one of ('
                             + ', '.join(list(_data_types.keys()))
                             + ').')
        # data_type and data_storage_types must be in the lookup.
        if data_storage_type not in _data_types:
            raise ValueError('data_storage_type must be one of ('
                             + ', '.join(list(_data_types.keys()))
                             + ').')

        # Validate chunks to make sure it is None, True, a tuple of two
        # ints, or a tuple of an int and None. All integers must be
        # positive.

        if chunks is None:
            chunks = (1024, int(Info['NumberChannels']))
        elif chunks is True:
            pass
        elif not isinstance(chunks, tuple) or len(chunks) != 2:
            raise ValueError('chunks must be None, True, or a tuple '
                             + 'an integer as the first element and '
                             + 'either an integer or None in the '
                             + 'second.')
        elif not isinstance(chunks[0], int) or chunks[0] < 1:
            raise ValueError('chunks must be None, True, or a tuple '
                             + 'an integer as the first element and '
                             + 'either an integer or None in the '
                             + 'second.')
        elif chunks[1] is None:
            chunks = (chunks[0], int(Info['NumberChannels']))
        elif not isinstance(chunks[1], int) or chunks[1] < 1:
            raise ValueError('chunks must be None, True, or a tuple '
                             + 'an integer as the first element and '
                             + 'either an integer or None in the '
                             + 'second.')

        # All inputs are validated.

        # Pack all of the information together, including putting in
        # placeholders for the start time and the number of samples
        # taken. The file type and software information is also put
        # in.

        software = __name__ + ' ' + __version__ + ' on ' \
            + platform.python_implementation() + ' ' \
            + platform.python_version()

        self._file_data = { \
            'Type': np.bytes_('Acquisition HDF5'), \
            'Version': np.bytes_(new_version), \
            'Software': np.bytes_(software), \
            'Info': Info, \
            'Data': { \
            'Type': _convert_to_numpy_bytes(data_type), \
            'StorageType': _convert_to_numpy_bytes(data_storage_type)}}

        self._file_data['Info']['StartTime'] = np.zeros(shape=(6,),
                                                        dtype='float64')
        self._file_data['Info']['NumberSamples'] = np.int64(0)

        # Write it all to file, truncating it if it exists. Python
        # information should not be stored, and matlab compatibility
        # should not be done. While the former would make it easier to
        # read the strings back in the same format
        hdf5storage.write(self._file_data, path='/', filename=filename,
                          truncate_existing=True,
                          store_python_metadata=False,
                          matlab_compatible=False)

        # Create a growable empty DataSet for the data with all the
        # storage options set, and then keep the file handle around for
        # later. If an exception occurs, the file needs to be closed if
        # it was opened and the exception re-raised so that the caller
        # knows about it. Nothing other than that needs to be done.

        try:
            self._file = h5py.File(filename)

            self._file['/Data'].create_dataset('Data', \
                shape=(0, Info['NumberChannels']), \
                dtype=_data_types[data_storage_type], \
                maxshape=(None, Info['NumberChannels']), \
                compression=compression, \
                compression_opts=compression_opts, \
                shuffle=shuffle, \
                fletcher32=fletcher32, \
                chunks=chunks)

            self._file.flush()
        except:
            if self._file is not None:
                self._file.close()
            raise

    def __del__(self):
        self.flush()
        if isinstance(self._file, h5py.File):
            self._file.flush()
            self._file.close()

    def flush(self):
        # Doesn't do anything right now because everything is just
        # written without concern for chunking, but it needs to be here
        # for later when the writing is done better.
        pass

    def add_data(self, data, flush_buffer=True):
        # Check to see if data matches the right data format and shape.
        if not isinstance(data, np.ndarray) or len(data.shape) != 2 \
                or data.shape[1] \
                != self._file_data['Info']['NumberChannels']:
            raise ValueError('data is not the right type, shape, or '
                             + 'format.')

        # Resize the Dataset to fit data and then append it onto the
        # end. If the dtypes don't match, it is converted (storage type
        # and acquired type need not be the same).
        dset = self._file['/Data/Data']
        old_shape = dset.shape
        dset.resize((old_shape[0] + data.shape[0], old_shape[1]))
        if data.dtype.name == dset.dtype.name:
            dset[old_shape[0]:dset.shape[0], :] = data
        else:
            dset[old_shape[0]:dset.shape[0], :] = dset.dtype.type(data)

        # Set NumberSamples to the new value.
        self._file_data['Info']['NumberSamples'] = \
            np.int64(dset.shape[0])
        self._file['/Info/NumberSamples'][()] = \
            self._file_data['Info']['NumberSamples']

        # Flush the changes to disk so nothing is lost if we hang.
        self._file.flush()

    @property
    def number_samples(self):
        self._file_data['Info']['NumberSamples']

    @property
    def StartTime(self):
        return self._file['/Info/StartTime'][...]

    @StartTime.setter
    def StartTime(self, value):
        if type(value) == np.ndarray and value.dtype.name == 'float64' \
                and value.shape == (6, ):
            self._file['/Info/StartTime'][:] = value


class Reader(object):
    def __init__(self, filename):
        self._filename = filename

        # Get and check the file type.
        file_type = hdf5storage.read(path='/Type',
                                     filename=filename)[()].decode()
        if file_type != 'Acquisition HDF5':
            raise NotImplementedError('Unsupported file type.')

        # Get and check the version.
        self.Version = hdf5storage.read(path='/Version',
                                        filename=filename)[()].decode()
        self._supported_version = \
            _get_supported_version(self.Version)
        if self._supported_version is None:
            raise NotImplementedError('Unsupported Acquisition '
                                      + 'HDF5 version: '
                                      + self.Version)

        # If it is version 1.1.0 or newer, it will have the Software
        # field which we want to grab (set to None otherwise).
        if LooseVersion(self._supported_version) \
                >= LooseVersion('1.1.0'):
            self.Software = hdf5storage.read( \
                path='/Software', filename=filename)[()].decode()
        else:
            self.Software = None

        # Read the Info field and convert it to a dict from a structred
        # ndarray if it isn't a dict already.
        info = hdf5storage.read(path='/Info', filename=filename)
        if isinstance(info, dict):
            self.Info = info
        else:
            self.Info = dict()
            for field in info.dtype.names:
                self.Info[field] = info[field][0]

        # Convert string types to str from np.bytes_.
        for k, v in self.Info.items():
            if isinstance(v, np.bytes_):
                self.Info[k] = v.decode()

        # Grab and check the type and storage type.
        tp = hdf5storage.read(path='/Data/Type',
                              filename=filename)[()].decode()
        if tp not in _data_types:
            raise NotImplementedError('Unsupported data type: '
                                        + tp)
        self.Type = _data_types[tp]
        tp = hdf5storage.read(path='/Data/StorageType',
                              filename=filename)[()].decode()
        if tp not in _data_types:
            raise NotImplementedError('Unsupported storage type: '
                                        + tp)
        self.StorageType = _data_types[tp]

        # Check that /Data/Data is present.
        with h5py.File(filename, 'r') as f:
            if '/Data/Data' not in f:
                raise NotImplementedError('Couldn''t find the acquired '
                                          'data.')

    @property
    def data_path(self):
        return '/Data/Data'

    def __getitem__(self, k):
        with h5py.File(self._filename, 'r') as f:
            shape = f[self.data_path].shape
            data = f[self.data_path][k]
        # Convert the type if necessary.
        if self.Type != self.StorageType:
            data = self.Type(data)

        # Figure out which channels were read.
        if isinstance(k, type(Ellipsis)) or len(k) == 1:
            channels = [i for i in range(shape[1])]
        elif isinstance(k[1], int):
            channels = [k[1]]
        else:
            channels = [i for i in range(shape[1])][k[1]]

        # Transform any channels with a non-zero offset or non-unity
        # scaling.
        for i in range(0, len(channels)):
            ch = channels[i]
            offset = self.Info['Offsets'][ch]
            scaling = self.Info['Scalings'][ch]
            if scaling != 1 and offset != 0:
                data[:, i] = scaling*data[:, i] + offset
            elif scaling != 1:
                data[:, i] *= scaling
            elif offset != 0:
                data[:, i] += offset

        # Done transforming data.
        return data
