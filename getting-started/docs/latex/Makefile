# LaTeX-Makefile
#
# Author: Jose Edil Medeiros
# Adapted from Ingo Sander original Makefile.
#
# Date: 20170205
#
# Description:
# This Makefile assumes the following project structure,
#
# base_dir
# | main.tex 	-- Main tex file
# | Makefile	-- This Makefile
# | src/	-- All included tex files (e.g. chapters)
# | include/	-- Style files
# | figs_src/	-- Source for figures (e.g. tikz, svg)
# | figs/	-- Compiled figures
#
# The name of the main file should be explicitly set in the DOCNAME
# variable. During execution of the Makefile, LaTeX-compatible figures
# are generated in the directory ./figs. For compilation of the main
# file, latexmk is invoked to deal with the multi step nature of LaTeX
# compilation.
#
# The following external tools are required:
# - TeXLive 2016.
# - latexmk, for compilation.
# - imagemagick, for figures convertion.
# - inkscape, for svg convertion.
# - xfig, for pictures convertion
#
# This Makefile assumes a MacOSX structure for application
# locations. Customize it for your own needs.
#
# The following rules are supported:
# make
# make clean
# make view


# Project-specific settings
DOCNAME = report

# Directory structure
UTILSDIR	= ../../../docutils
STYDIR		= ../../../docutils
FIGS_DIR 	= figs
S_FIGS_DIR	= figs_src
LATEXDIR	= input
LITERATEDIR	= code
CODEDIR		= ../../src/AtomExamples
BIBDIR		= ../../../docutils

# Tools
LATEXMK = latexmk
RM = rm -f
CP = cp
MV = mv
MKDIR = mkdir -p
OPEN = open
INKSCAPE = inkscape
A2PING = a2ping
FIG2DEV = fig2dev
CONVERT = awk
BIRD2TEX = $(UTILSDIR)/bird2tex.awk


# Figures source files
S_PDF_FIGS	:= $(shell find $(S_FIGS_DIR) -name '*.pdf')
S_EPS_FIGS	:= $(shell find $(S_FIGS_DIR) -name '*.eps')
S_TIKZ_FIGS	:= $(shell find $(S_FIGS_DIR) -name '*.tex')
S_SVG_FIGS	:= $(shell find $(S_FIGS_DIR) -name '*.svg')
S_JPG_FIGS	:= $(shell find $(S_FIGS_DIR) -name '*.jpg')
S_PNG_FIGS	:= $(shell find $(S_FIGS_DIR) -name '*.png')
S_XFIG_FIGS	:= $(shell find $(S_FIGS_DIR) -name '*.fig')

# Figures targets
PDF_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.pdf, $(FIGS_DIR)/%.pdf, $(S_PDF_FIGS))
EPS_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.eps, $(FIGS_DIR)/%.pdf, $(S_EPS_FIGS))
TIKZ_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.tex, $(FIGS_DIR)/%.pdf, $(S_TIKZ_FIGS))
SVG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.svg, $(FIGS_DIR)/%.pdf, $(S_SVG_FIGS))
JPG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.jpg, $(FIGS_DIR)/%.jpg, $(S_jpg_FIGS))
PNG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.png, $(FIGS_DIR)/%.png, $(S_PNG_FIGS))
XFIG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.fig, $(FIGS_DIR)/%.fig, $(S_XFIG_FIGS))

# Source files
BIBFILES	:= $(shell find $(BIBDIR) -name '*.bib')
LATEXFILES	:= $(shell find $(LATEXDIR) -name '*.tex')
UTILFILES	:= $(shell find $(UTILSDIR) -name '*.*')

# Rules for literate Haskell files
CODEFILES	:= $(shell find $(CODEDIR) -name '*.lhs')
LITERATEFILES	:= $(patsubst $(CODEDIR)/%.lhs, $(LITERATEDIR)/%.tex, $(CODEFILES))

# Targets
all: doc
doc: pdf
pdf: $(DOCNAME).pdf

# Rules
$(DOCNAME).pdf: $(DOCNAME).tex \
		figures $(LITERATEFILES) $(UTILFILES)
#		$(LATEXFILES) $(STYLEFILES) $(BIBFILES)
#               Makefile $(STYLEFILES) $(BIBFILES)
	@$(LATEXMK) -synctex=1 -quiet -silent -bibtex -pdf -cd- $(DOCNAME)

view: doc
	@$(OPEN) $(DOCNAME).pdf

mostlyclean:
	@$(LATEXMK) -silent -c
	@$(RM) *.bbl

clean: mostlyclean
	@$(LATEXMK) -silent -C
	@$(RM) *.run.xml *.synctex.gz
	@$(RM) *.d
	@$(RM) *.thm
	@$(RM) *.pdf
	@$(RM) -rf $(LITERATEDIR)/*

### Rules for converting literate programming
$(LITERATEFILES) : $(LITERATEDIR)/%.tex : $(CODEDIR)/%.lhs  
	@mkdir -p $(@D)
	@$(CONVERT) -f $(BIRD2TEX) $< > $@

figures:	$(PDF_FIGS) \
		$(EPS_FIGS) \
		$(XFIG_FIGS) \
		$(JPG_FIGS) \
		$(PNG_FIGS) \
		$(TIKZ_FIGS) \
		$(SVG_FIGS)

### Rules for figures
### These are Pattern Rules and will match in the
### order they appear in the Makefile

# Rule for SVG files: use inkscape to convert to pdf
figs/%.pdf: $(S_FIGS_DIR)/%.svg
	@$(MKDIR) $(@D)
	@$(INKSCAPE) -z -D --export-pdf=$@ $(<)

# Rule for original EPS figures: use a2ping to convert to pdf
GS_OPTS:= -dPDFX
figs/%.pdf: $(S_FIGS_DIR)/%.eps
	@$(MKDIR) $(@D)
	@$(A2PING) --gsextra='$(GS_OPTS)' --outfile=$@  $(<)

# Rule for original JPG figures: copy
figs/%.jpg: $(S_FIGS_DIR)/%.jpg
	@$(MKDIR) $(@D)
	@$(CP) $< $@
# Rule for original PNG figures: copy
figs/%.png: $(S_FIGS_DIR)/%.png
	@$(MKDIR) $(@D)
	@$(CP) $< $@

# Rules for Tikz and LaTeX figures
figs/%.pdf: $(S_FIGS_DIR)/%.tex
	@echo $(@F)
	TEXINPUTS=:$(S_FIGS_DIR)/:$(STYDIR)/ pdflatex $(*F)
	$(MV) $(@F) $@
	$(RM) *.log
	$(RM) *.aux

# Rule for FIG files (xfig)
# Create combined pdf/latex figures from .fig file
figs/%.pdf: $(S_FIGS_DIR)/%.fig
#	@$(MKDIR) $(@D)
#	$(FIG2DEV) -L pdftex -p dummy $(FIGS_SRC_DIR)/$*.fig > $(FIGS_DIR)/$*.pdf
#	$(FIG2DEV) -L pdftex_t -p $(FIGS_DIR)/$* $(FIGS_SRC_DIR)/$*.fig >        $(FIGS_DIR)/$*.pdf_t

# Rule for original PDF figures: copy
figs/%.pdf: $(S_FIGS_DIR)/%.pdf
	@$(MKDIR) $(@D)
	@$(CP) $< $@

.PHONY: all clean doc mostlyclean pdf figures

# Include auto-generated dependencies
-include *.d
