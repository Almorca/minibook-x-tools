# Top-level Makefile for Chuwi Minibook X Tools
#
# Copyright (c) 2025 Armando DiCianno <armando@noonshy.com>
#
# This Makefile coordinates builds across all components:
#   - cmx (kernel module)
#   - cmxd (system daemon)
#   - cmxsd (session daemon)

.PHONY: all help clean cmx cmxd cmxsd install install-cmx install-cmxd install-cmxsd uninstall uninstall-cmxd uninstall-cmxsd

# Default target
all: cmx cmxd cmxsd

# Help target
help:
	@echo "Chuwi Minibook X Tools - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build all components (default)"
	@echo "  cmx              - Build kernel module only"
	@echo "  cmxd             - Build system daemon only"
	@echo "  cmxsd            - Build session daemon only"
	@echo ""
	@echo "  clean            - Clean all build artifacts"
	@echo "  clean-cmx        - Clean kernel module build"
	@echo "  clean-cmxd       - Clean system daemon build"
	@echo "  clean-cmxsd      - Clean session daemon build"
	@echo ""
	@echo "  install          - Install all components (requires sudo)"
	@echo "  install-cmx      - Install kernel module (requires sudo)"
	@echo "  install-cmxd     - Install system daemon (requires sudo)"
	@echo "  install-cmxsd    - Install session daemon (requires sudo)"
	@echo ""
	@echo "  uninstall        - Uninstall cmxd and cmxsd (requires sudo)"
	@echo "  uninstall-cmxd   - Uninstall system daemon (requires sudo)"
	@echo "  uninstall-cmxsd  - Uninstall session daemon (requires sudo)"
	@echo ""
	@echo "Notes:"
	@echo "  - Build targets (all, cmx, cmxd, cmxsd, clean) do not require sudo"
	@echo "  - Install/uninstall targets automatically use sudo"
	@echo "  - cmx has no uninstall target (use 'sudo rmmod cmx' to unload)"

# Build targets (no sudo required)
cmx:
	@echo "==> Building cmx kernel module..."
	$(MAKE) -C cmx

cmxd:
	@echo "==> Building cmxd system daemon..."
	$(MAKE) -C cmxd

cmxsd:
	@echo "==> Building cmxsd session daemon..."
	$(MAKE) -C cmxsd

# Clean targets (no sudo required)
clean: clean-cmx clean-cmxd clean-cmxsd
	@echo "==> All components cleaned"

clean-cmx:
	@echo "==> Cleaning cmx kernel module..."
	$(MAKE) -C cmx clean

clean-cmxd:
	@echo "==> Cleaning cmxd system daemon..."
	$(MAKE) -C cmxd clean

clean-cmxsd:
	@echo "==> Cleaning cmxsd session daemon..."
	$(MAKE) -C cmxsd clean

# Install targets (automatically use sudo)
install: install-cmx install-cmxd install-cmxsd
	@echo "==> All components installed"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Load kernel module:    sudo modprobe cmx"
	@echo "  2. Start system daemon:   sudo systemctl enable --now cmxd"
	@echo "  3. Start session daemon:  systemctl --user enable --now cmxsd"

install-cmx:
	@echo "==> Installing cmx kernel module..."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Running 'make modules_install' in cmx/ with sudo..."; \
		cd cmx && sudo $(MAKE) modules_install; \
	else \
		$(MAKE) -C cmx modules_install; \
	fi

install-cmxd:
	@echo "==> Installing cmxd system daemon..."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Running 'make install' in cmxd/ with sudo..."; \
		cd cmxd && sudo $(MAKE) install; \
	else \
		$(MAKE) -C cmxd install; \
	fi

install-cmxsd:
	@echo "==> Installing cmxsd session daemon..."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Running 'make install' in cmxsd/ with sudo..."; \
		cd cmxsd && sudo $(MAKE) install; \
	else \
		$(MAKE) -C cmxsd install; \
	fi

# Uninstall targets (automatically use sudo)
uninstall: uninstall-cmxd uninstall-cmxsd
	@echo "==> cmxd and cmxsd uninstalled"
	@echo ""
	@echo "Note: cmx kernel module has no uninstall target"
	@echo "      Use 'sudo rmmod cmx' to unload the module"

uninstall-cmxd:
	@echo "==> Uninstalling cmxd system daemon..."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Running 'make uninstall' in cmxd/ with sudo..."; \
		cd cmxd && sudo $(MAKE) uninstall; \
	else \
		$(MAKE) -C cmxd uninstall; \
	fi

uninstall-cmxsd:
	@echo "==> Uninstalling cmxsd session daemon..."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Running 'make uninstall' in cmxsd/ with sudo..."; \
		cd cmxsd && sudo $(MAKE) uninstall; \
	else \
		$(MAKE) -C cmxsd uninstall; \
	fi
