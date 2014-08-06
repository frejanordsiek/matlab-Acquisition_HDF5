import sys

if sys.hexversion < 0x3000000:
    raise NotImplementedError('Python < 3.0 not supported.')

import ez_setup
ez_setup.use_setuptools()

from setuptools import setup

with open('README.rst') as file:
    long_description = file.read()

setup(name='Acquisition_HDF5',
      version='0.1',
      description='Utilities to read from and write to an HDF5 based acquisition file format for DAQs.',
      long_description=long_description,
      author='Freja Nordsiek',
      author_email='fnordsie at gmail dt com',
      url='https://github.com/frejanordsiek/Acquisition_HDF5',
      py_modules=['Acquisition_HDF5'],
      requires=['numpy', 'h5py', 'hdf5storage'],
      license='BSD',
      keywords='hdf5 acquisition DAQ',
      classifiers=[
          "Programming Language :: Python :: 3",
          "Development Status :: 3 - Alpha",
          "License :: OSI Approved :: BSD License",
          "Operating System :: OS Independent",
          "Intended Audience :: Developers",
          "Intended Audience :: Information Technology",
          "Intended Audience :: Science/Research",
          "Topic :: Scientific/Engineering",
          "Topic :: Database",
          "Topic :: Software Development :: Libraries :: Python Modules",
          "Topic :: System :: Archiving"
          ],
      )
