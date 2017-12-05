REPORTS = ../../getting-started ../../hybrid

# Project-specific settings
DOCNAME = manual
TITLEPG = title

# Directory structure
UTILSDIR	= ../
STYDIR		= ../
BIBDIR		= ../docfiles

# Tools
MAKE = make
RM = rm -f
CP = cp
MV = mv
MKDIR = mkdir -p
OPEN = evince

BIBFILES     = $(wildcard $(BIBDIR)/*.bib)
TEXFILES     = $(wildcard $(UTILSDIR)/*.tex)
STYLEFILES   = $(wildcard $(STYDIR)/*.sty)

.PHONY: manual reports $(REPORTS) title doc view clean superclean

# Targets
manual: reports title doc

reports: $(REPORTS)
title: $(TITLEPG).pdf
doc: ../../$(DOCNAME).pdf

view: manual
	@$(OPEN) ../../$(DOCNAME).pdf

clean:
	@$(RM) *.aux *~ *.log *.gz *.dvi *.blg *.bbl *.tmp \
		*.thm *.toc *.lo* *# *.mtc* *.out *.xml \
		*.maf *.bcf comment.cut

superclean: clean
	@$(RM) -f $(TITLEPG).pdf
	@$(RM) -f ../../$(DOCNAME).pdf
	@for report in $(REPORTS); do \
		@$(MAKE) -C $@ clean-docs \
	done

# Rules

$(REPORTS):
	@$(MAKE) -C $@ report

$(TITLEPG).pdf:
	pdflatex --shell-escape $(TITLEPG)  > /dev/null


../../$(DOCNAME).pdf: $(DOCNAME).tex \
		$(TEXFILES) $(STYLEFILES) $(BIBFILES) \
                $(DOCNAME).bbl Makefile
	pdflatex --shell-escape $(DOCNAME) > /dev/null
	biber $(DOCNAME)  > /dev/null
	pdflatex $(DOCNAME)  > /dev/null
	@while ( grep "Rerun to get cross-references" 	\
	$(DOCNAME).log > /dev/null ); do		\
	        echo '** Re-running LaTeX **';		\
	        pdflatex $(DOCNAME) > /dev/null;        \
	done
	@mv $(DOCNAME).pdf ../../

$(DOCNAME).bbl : $(DOCNAME).tex $(BIBFILES)
	pdflatex $(DOCNAME).tex > /dev/null
	biber $(DOCNAME) > /dev/null

