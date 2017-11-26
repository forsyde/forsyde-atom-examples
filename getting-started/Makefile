ATOM_VER := 0.2.1.1
ATOM_LIB := ../.deps/forsyde-atom-v$(ATOM_VER)
ATOM_URL := -b $(ATOM_VER) https://github.com/forsyde/forsyde-atom.git

LATEX_LIB := ../.deps/forsyde-latex
LATEX_URL := -b dev-atom https://github.com/forsyde/forsyde-latex.git

API_PATH := docs/api
REPORT_PATH := docs/latex

dependencies:
	@mkdir -p ../.deps
	@if [ ! -d $(LATEX_LIB) ]; then \
		git clone $(LATEX_URL) $(LATEX_LIB); \
	fi
	@if [ ! -d $(ATOM_LIB) ]; then \
		git clone $(ATOM_URL) $(ATOM_LIB); \
	fi
	cd $(LATEX_LIB) && ./install.sh
	@if ! haddock --version; then cabal install haddock; fi
	@if ! hscolour --version; then cabal install hscolour; fi

install: dependencies
	cabal sandbox init
	cabal sandbox add-source $(ATOM_LIB)
	cabal fetch `cabal install --dependencies-only --dry-run | sed 1,2d  | grep -v '^forsyde'`
	cabal install

api:
	@cabal configure
	@rm -rf $(API_PATH)
	@cabal haddock --hyperlink-source | awk 'END {print $$NF}' | xargs dirname | xargs -I {} mv {} $(API_PATH)

report:
	@$(MAKE) -C $(REPORT_PATH)

docs: dependencies api report
	@echo
	@echo "====================================================="
	@echo "= API documentation generated in $(API_PATH)/index.html"
	@echo "= Report generated in $(REPORT_PATH)/report.pdf"
	@echo "====================================================="

clean-docs:
	$(MAKE) -C docs/latex/ superclean
	rm -rf docs/api/*

uninstall: clean-docs
	cabal sandbox delete

remove: uninstall
	rm -rf $(ATOM_LIB)
	rm -rf $(LATEX_LIB)

.PHONY: dependencies install docs api report uninstall remove
