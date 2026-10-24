SJASMPLUS ?= sjasmplus
PYTHON ?= python3

.PHONY: all assets previews test test-emulator captures
all:
	$(SJASMPLUS) --sym=resources/generated/sebollas.sym Sebollas.asm

assets:
	$(PYTHON) tools/build_assets.py

previews:
	$(PYTHON) tools/render_previews.py

test: all
	$(PYTHON) tests/test_assets.py

test-emulator: all
	openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -script tests/openmsx_suite.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -script tests/openmsx_suite.tcl
	openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -script tests/stress.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -script tests/stress.tcl
	$(PYTHON) tests/check_emulator_results.py

captures: all
	openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -script tests/capture.tcl
	$(PYTHON) tools/finish_captures.py
	$(PYTHON) tests/check_capture.py
