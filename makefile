TCL_SCRIPT_NAME=tarefas.tcl
TCL_REPORT=report.txt

SHELL_SCRIPT_NAME=script.sh
SHELL_SCRIPT_FLAGS=--dry-run

tcl: $(TCL_SCRIPT_NAME)
	@if [ ! -f $(TCL_REPORT) ]; then \
		tclsh $(TCL_SCRIPT_NAME) | tee $(TCL_REPORT); \
	else \
		echo "$(TCL_REPORT) já existe"; \
	fi

shell: $(SHELL_SCRIPT_NAME)
	@./$(SHELL_SCRIPT_NAME) $(SHELL_SCRIPT_FLAGS)

clean: $(TCL_REPORT)
	rm -f $(TCL_REPORT)