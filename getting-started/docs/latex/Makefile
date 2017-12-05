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
UTILSDIR	= ../../../docfiles
STYDIR		= ../../../docfiles
FIGS_DIR 	= figs
S_FIGS_DIR	= figs_src
LATEXDIR	= input
LITERATEDIR	= code
CODEDIR		= ../../src/AtomExamples
BIBDIR		= ../../../docfiles

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
EPS_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.eps, $(FIGS_DIR)/%.eps, $(S_EPS_FIGS))
TIKZ_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.tex, $(FIGS_DIR)/%.pdf, $(S_TIKZ_FIGS))
SVG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.svg, $(FIGS_DIR)/%.pdf, $(S_SVG_FIGS))
JPG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.jpg, $(FIGS_DIR)/%.jpg, $(S_jpg_FIGS))
PNG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.png, $(FIGS_DIR)/%.png, $(S_PNG_FIGS))
XFIG_FIGS	:= $(patsubst $(S_FIGS_DIR)/%.fig, $(FIGS_DIR)/%.fig, $(S_XFIG_FIGS))

# Source files
BIBFILES     = $(wildcard $(BIBDIR)/*.bib)
LATEXFILES   = $(wildcard $(LATEXDIR)/*.tex)
TEXFILES     = $(wildcard $(UTILSDIR)/*.tex)
STYLEFILES   = $(wildcard $(STYDIR)/*.sty)
# UTILFILES	:= $(shell find $(UTILSDIR) -name '*.*')
# BIBFILES	:= $(shell find $(BIBDIR) -name '*.bib')
# LATEXFILES	:= $(shell find $(LATEXDIR) -name '*.tex')

# Rules for literate Haskell files
CODEFILES	:= $(shell find $(CODEDIR) -name '*.lhs')
LITERATEFILES	:= $(patsubst $(CODEDIR)/%.lhs, $(LITERATEDIR)/%.tex, $(CODEFILES))

# Targets
all: doc
doc: pdf
pdf: $(DOCNAME).pdf

# Rules
$(DOCNAME).pdf: $(DOCNAME).tex \
		figures $(LITERATEFILES) $(TEXFILES) \
		$(LATEXFILES) $(STYLEFILES) $(BIBFILES) \
                $(DOCNAME).bbl Makefile $(STYLEFILES) $(BIBFILES)
	@echo "Making  $(DOCNAME)"
	pdflatex --shell-escape $(DOCNAME) $(DEBUG)
	biber --validate_datamodel $(DOCNAME)
	pdflatex $(DOCNAME) $(DEBUG)
	@while ( grep "Rerun to get cross-references" 	\
	$(DOCNAME).log > /dev/null ); do		\
	        echo '** Re-running LaTeX **';		\
	        pdflatex $(DOCNAME)  $(DEBUG);		\
	done

view: doc
	@$(OPEN) $(DOCNAME).pdf

clean:
	@find . -name "*.aux" -type f -delete
	@find . -name "*~" -type f -delete
	@find . -name "*.log" -type f -delete
	@find . -name "*.gz" -type f -delete
	@find . -name "*.dvi" -type f -delete
	@find . -name "*.blg" -type f -delete
	@find . -name "*.bbl" -type f -delete
	@find . -name "*.tmp" -type f -delete
	@find . -name "*.thm" -type f -delete
	@find . -name "*.toc" -type f -delete
	@find . -name "*.lo*" -type f -delete
	@find . -name "*#" -type f -delete
	@find . -name "*.out" -type f -delete
	@find . -name "comment.cut" -type f -delete

superclean: clean
	@$(RM) -f ./figs/*
	@$(RM) -rf $(LITERATEDIR)/*
	@$(RM) *.pdf

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
figs/%.eps: $(S_FIGS_DIR)/%.eps
	@$(MKDIR) $(@D)
	@$(CP) $< $@
#	@$(A2PING) --gsextra='$(GS_OPTS)' --outfile=$@  $(<)

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
	@$(MKDIR) $(@D)
	@TEXINPUTS=:$(S_FIGS_DIR)/:$(STYDIR)/ pdflatex $(*F) $(DEBUG)
	@$(MV) $(@F) $@
	@$(RM) *.log
	@$(RM) *.aux

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

$(DOCNAME).bbl : $(DOCNAME).tex $(BIBFILES)
	pdflatex $(DOCNAME).tex $(DEBUG)
	biber --validate_datamodel $(DOCNAME) $(DEBUG)

.PHONY: all clean superclean doc pdf

# Include auto-generated dependencies
-include *.d
