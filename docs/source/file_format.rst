
.. |matlab| replace:: MATLAB\ :superscript:`®`
.. |data_acquisition_toolbox| replace:: Data Acquisition Toolbox\ :superscript:`™`

===========
File Format
===========


Introduction
============

This is a file format for saving data acquired from a DAQ to disk in
real time for later processing. A format is needed that is not locked
to one vendor and/or platform, is easy to decipher and reverse engineer,
uses compression, and is salvageale if acquisition terminates
prematurely. These are all traits that the ``'.daq'`` format used by the
|matlab| |data_acquisition_toolbox|
(http://www.mathworks.com/products/daq/), which this format is inspired
by/based on, lacks.

It is a Heirarchal Data Format version 5 (HDF5) based file format. HDF5
is a widely used open portable scientific data interchange format
(http://www.hdfgroup.org/HDF5/), has open libraries for parsing the
files and reading their contents that can be interfaced by many
programming languages/environments on all the major OS's, has a
graphical viewer that allows visual inspection of the contents of the
files (critical for reverse engineering), supports compression, and
handles the intricities of how numbers, especially floating point
numbers, are internally represented on different computer platforms.

HDF5 files are set up in a heirarchal format modeled after the Unix
filesystem with Groups as directories and Datasets as files. They are
even accessed like files on a Unix filesystem as in
``'/Info/DeviceName'``. While HDF5 files support the use of attributes
for both Groups and Datasets, this file format does not use them, but
instead stores all metadata in their own Datasets. These files store
file format identification information in the root Group ``'/'`` ;
information about the data acquisition system, hardware, and acquisition
parameters in the Group ``'/Info'`` ; and the actual acquired data and
information on its target and stored binary formats in Group
``'/Data'``. Note, HDF5 uses C style array dimension order, as opposed
to Fortran ordering (shared by |matlab|), which is row-column order.

.. note::
   
   While HDF5 files support the use of Attributes on Datasets and
   Groups, they are not used in this file format and are ignored if
   present.


File Versions
=============

0.0.1 -- 1.0.0. Initial version (all versions in this range are the same).
             * Only storing a single trigger of the DAQ per file is
               supported

1.1.0. Added the ``'/Software'`` field.


Storage And Extraction
======================

When acquiring with a DAQ, the data is typically returned by the driver
in a raw/native form from each of the channels. This data is generally
meant to be linearly scaled and an offset added when converted to
floating point numbers for actual processing, assuming it isn't already
in floating point format. The conversion is

.. math:: A = S \cdot A_r + D
   :label: eqn:scaling

.. |A_r| replace:: A\ :subscript:`r`
.. |A| replace:: A
.. |S| replace:: S
.. |D| replace:: D

where |A_r| is the raw/native data, |S| is the scaling factor, |D| is the offset, and |A| is the scaled data.

The raw/native data, |A_r|, is stored in the file and it should be type
converted and scaled by Equation :eq:`eqn:scaling` before it is used.
Now, the raw/native datatype could be signed or unsigned integers of a
given bit depth or it may be a floating point number (some DAQ's do
temperature compensation before returning the acquired samples). This
datatype is stored in the file for ease of identification. As it is
sometimes useful to store the data with a lower bit depth to save space
when one knows it won't affect the accuracy appreciably (negligible
overflows and/or rounding), saving the data in a different data type is
supported, which is also stored in the file. Using the data type that
the acquired data is stored as (see ``'/Data/StorageType'``), the target
data type (see ``'/Data/Type'``), the scaling factors for each channel
(see ``'/Info/Scalings'``), and the offsets for each channel (see
``'/Info/Offsets'``); |A| in Equation :eq:`eqn:scaling` can be
constructed from the raw data |A_r| (see ``'/Data/Data'``).

The acquired data can optionally be compressed or have other filters
applied to it. For portability, it is highly recommended to only use
filters and non-proprietary compression algorithms (only the Deflate
algorithm) contained in the HDF5 library. Chunking is strongly
encouraged.


Datasets
========

The datasets are described in the table below. The first version of the
file format the Dataset appears in (blank if in all of them), the size
(dimensions) of the Dataset in row-column order (scalar means
0-dimensional and a single number means 1-dimensional), its type, and
its description are all given.

+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| Dataset                       | Version | Size   | Type         | Description                                                                                  |
+===============================+=========+========+==============+==============================================================================================+
| /Type                         |         | scalar | ASCII string | Type of file format, which is always ``'Acquisition HDF5'``.                                 |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Version                      |         | scalar | ASCII string | Version of file format (e.g. ``'1.1.0'``).                                                   |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Software                     | 1.1.0   | scalar | ASCII string | Software that made the file.                                                                 |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Data/Data                    |         | N x M  | Store Type   | The acquired data is stored in the format specified by ``'/Data/StorageFormat'``.            |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Data/StorageType             |         | scalar | ASCII string | Type that the data is stored as. [1]_                                                        |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Data/Type                    |         | scalar | ASCII string | Type the data should have after extraction. [1]_                                             |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/Bits                    |         | scalar | Int64        | Bit depth of the ADC.                                                                        |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/ChannelInputRanges      |         | M x 2  | Float64      | One row per channel (in order) specifying the input ranges in minimum, maximum order.        |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/ChannelMappings         |         | M      | Int64        | The hardware channels corresponding to each acquired channel (in order).                     |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/ChannelNames            |         | M      | ASCII string | The names of each channel in order.                                                          |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/DeviceName              |         | scalar | ASCII string | The name of the DAQ device (model).                                                          |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/ID                      |         | scalar | ASCII string | The ID of the DAQ device (which one if more than one is connected).                          |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/InputType               |         | scalar | ASCII string | Analog input type (e.g. ``'SingleEnded'``, ``'Differential'``, etc.).                        |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/NumberChannels          |         | scalar | Int64        | M, the number of channels acquired from.                                                     |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/NumberSamples           |         | scalar | Int64        | N, the number of acquired samples from each channel.                                         |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/Offsets                 |         | M      | Float64      | The offsets, |D|, for each channel in order.                                                 |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/SampleFrequency         |         | scalar | Float64      | The sample frequency in Hz.                                                                  |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/Scalings                |         | M      | Float64      | The scaling factors, |S|, for each channel in order.                                         |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/StartTime               |         | 6      | Float64      | The time at which acquisition was triggered (year, month, day, hour, minute, seconds order). |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/TriggerType             |         | scalar | ASCII string | The type of trigger starting acquisition (e.g. ``'hardware'``, ``'software'``, etc.).        |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/Units                   |         | M      | ASCII string | The units of the measurment of each channel in order (e.g. ``'volts'``, ``'amps'``, etc.).   |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+
| /Info/VendorDriverDescription |         | scalar | ASCII string | The hardware vendor and driver.                                                              |
+-------------------------------+---------+--------+--------------+----------------------------------------------------------------------------------------------+

.. [1] Must be a valid string label for the data type in the table
       below.

       =======  ============
       Type     String
       =======  ============
       Float32  ``'single'``
       Float64  ``'double'``
       Int8     ``'int8'``
       Int16    ``'int16'``
       Int32    ``'int32'``
       Int64    ``'int64'``
       Uint8    ``'uint8'``
       Uint16   ``'uint16'``
       Uint32   ``'uint32'``
       Uint64   ``'uint64'``
       =======  ============


Many of the Datasets in the ``'/Info'`` Group have |matlab|
|data_acquisition_toolbox| equivalents in the ``daqinfo`` structure
returned by reading an acquisition file. The equivalences are shown in
the table below.

=============================  ===========================================
Dataset                        |matlab| equivalent
=============================  ===========================================
/Info/Bits                     ``daqinfo.HwInfo.Bits``
/Info/ChannelInputRanges       ``daqinfo.ObjInfo.Channel(:).InputRange``
/Info/ChannelMappings          ``daqinfo.ObjInfo.Channel(:).HwChannel``
/Info/ChannelNames             ``daqinfo.ObjInfo.Channel(:).ChannelName``
/Info/DeviceName               ``daqinfo.HwInfo.DeviceName``
/Info/ID                       ``daqinfo.HwInfo.ID``
/Info/InputType                ``daqinfo.ObjInfo.InputType``
/Info/NumberChannels
/Info/NumberSamples            ``daqinfo.ObjInfo.SamplesAcquired``
/Info/Offsets                  ``daqinfo.ObjInfo.Channel(:).NativeOffset``
/Info/SampleFrequency          ``daqinfo.ObjInfo.SampleRate``
/Info/Scalings                 ``daqinfo.ObjInfo.Channel(:).NativeOffset``
/Info/StartTime                ``daqinfo.ObjInfo.InitialTriggerTime``
/Info/TriggerType              ``daqinfo.ObjInfo.TriggerType``
/Info/Units                    ``daqinfo.ObjInfo.Channel(:).Units``
/Info/VendorDriverDescription  ``daqinfo.HwInfo.VendorDriverDescription``
=============================  ===========================================
