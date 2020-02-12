# This file is intended for installation in UNIX based systems
SHELL = /bin/sh
INSTALL = install
INSTALL_DATA = $(INSTALL) -m 0555
INSTALL_DIR = $(INSTALL) -d -m 0755

software_name = tmux-resurrect
prefix = /usr/local
datadir = $(prefix)/share
srcdir = $(prefix)/src
software_srcdir = $(srcdir)/$(software_name)
software_datadir = $(DESTDIR)$(datadir)/$(software_name)

files = \
resurrect.tmux \
save_command_strategies/gdb.sh \
save_command_strategies/linux_procfs.sh \
save_command_strategies/pgrep.sh \
save_command_strategies/ps.sh \
scripts/check_tmux_version.sh \
scripts/helpers.sh \
scripts/process_restore_helpers.sh \
scripts/restore.exp \
scripts/restore.sh \
scripts/save.sh \
scripts/spinner_helpers.sh \
scripts/tmux_spinner.sh \
scripts/variables.sh \
strategies/irb_default_strategy.sh \
strategies/mosh-client_default_strategy.sh \
strategies/nvim_session.sh \
strategies/vim_session.sh

subdirs = \
save_command_strategies \
scripts \
strategies

# It is important to leave two empty lines between define and endef.
# Between those there is a newline character that gets inserted when ${\n} is used.
define \n


endef

.PHONY: all
all:
	@echo "This is the default target and does nothing. Use 'make install' to install"

.PHONY: install
install: installdirs
	$(foreach filename, $(files), $(INSTALL_DATA) $(software_srcdir)/$(filename) $(software_datadir)/$(filename)${\n})
	@echo "$(software_name) is installed :)"

.PHONY: uninstall
uninstall:
	$(foreach filename, $(files), rm $(software_datadir)/$(filename)${\n})
	$(foreach dirname, $(subdirs), rmdir $(software_datadir)/$(dirname)${\n})
	@echo "$(software_name) is uninstalled :)"

.PHONY: installdirs
installdirs:
	$(INSTALL_DIR) $(software_datadir)
	$(foreach dirname, $(subdirs), $(INSTALL_DIR) $(software_datadir)/$(dirname)${\n})
