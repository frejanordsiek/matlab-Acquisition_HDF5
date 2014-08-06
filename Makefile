# Makefile to build documentation.
#
# Author:  Freja Nordsiek
# Notes:
# History: * 2013-12-03: Created 

# Basic definitions.

RM  = rm -f
PDFLATEX = pdflatex

# Define the targets to be built.

TARGETS = latex/Acquisition_HDF5.pdf

all: $(TARGETS)

.SUFFIXES: .tex

.PHONY: clean

clean:
	$(RM) $(TARGETS)
	$(RM) latex/*.aux
	$(RM) latex/*.log
	$(RM) latex/*.out
	$(RM) latex/*.toc

%.pdf: %.tex
	$(RM) $*.aux
	$(RM) $*.out
	$(RM) $.toc
	$(PDFLATEX) -output-directory=$(@D) -output-format=pdf $<
	$(PDFLATEX) -output-directory=$(@D) -output-format=pdf $<

