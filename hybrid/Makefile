API_PATH 	= docs/api
REPORT_PATH 	= docs/latex

install: 
	stack install

api:
	@rm -rf $(API_PATH)
	@stack haddock | awk 'END {print $$NF}'

report: ./docs/latex/report.pdf

docs: api report
	@echo
	@echo "====================================================="
	@echo "= Check output of 'stack haddock' for API path"
	@echo "= Report generated in $(REPORT_PATH)/report.pdf"
	@echo "====================================================="

clean-docs:
	$(MAKE) -C $(REPORT_PATH) superclean

uninstall: clean-docs
	rm -rf .stack-work

.PHONY: dependencies install docs api report uninstall remove


./docs/latex/report.pdf:
	@$(MAKE) -C $(REPORT_PATH) DEBUG="> /dev/null"
