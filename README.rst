.. |matlab| replace:: MATLAB\ :superscript:`®`
.. |data_acquisition_toolbox| replace:: Data Acquisition Toolbox\
					:superscript:`™`

=========================
|matlab| Acquisition HDF5
=========================

|matlab| |data_acquisition_toolbox|
(http://www.mathworks.com/products/daq/) bindings to use the
[Acquisition HDF5](https://github.com/frejanordsiek/Acquisition_HDF5)
file format instead of the native ``.daq`` format. The file format,
documented at
https://github.com/frejanordsiek/Acquisition_HDF5/blob/master/docs/source/file_format.rst,
is Heirarchal Data Format version 5 (HDF5) based. HDF5 is a widely used
open portable scientific data interchange format
(http://www.hdfgroup.org/HDF5/), has open libraries for parsing the
files and reading their contents that can be interfaced by many
programming languages/environments on all the major OS's, has a
graphical viewer that allows visual inspection of the contents of the
files (critical for reverse engineering), supports compression, and
handles the intricities of how numbers, especially floating point
numbers, are internally represented on different computer
platforms. Where as the |matlab| |data_acquisition_toolbox| ``.daq``
format is needed is locked to one vendor and limited platforms, is hard
to decipher and reverse engineer, does not use compression, and is
generally not salvageale if acquisition terminates prematurely.

This project was originally contained in [Acquisition
HDF5](https://github.com/frejanordsiek/Acquisition_HDF5) but has been
separated off so that they can develop independently as well as making
project versioning easier.

