SJASMPLUS ?= sjasmplus
PYTHON ?= python3

.PHONY: all assets music previews test test-emulator captures
all:
	$(SJASMPLUS) --sym=resources/generated/sebollas.sym Sebollas.asm

assets:
	$(PYTHON) tools/build_assets.py
	$(PYTHON) tools/build_title.py
	$(PYTHON) tools/build_ending.py
	$(PYTHON) tools/build_music.py
	$(PYTHON) tools/build_ending_music.py

music:
	$(PYTHON) tools/build_music.py
	$(PYTHON) tools/build_ending_music.py

previews:
	$(PYTHON) tools/render_previews.py

test: all
	$(PYTHON) tests/test_assets.py

test-emulator: all
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/openmsx_suite.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/openmsx_suite.tcl
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/frame_skip.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/frame_skip.tcl
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/secret_menu.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/secret_menu.tcl
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/ending_music.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/ending_music.tcl
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/ending_sequence.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/ending_sequence.tcl
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/stress.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/stress.tcl
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/route_playthrough.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/route_playthrough.tcl
	openmsx -machine C-BIOS_MSX2_EU -cart Sebollas.rom -romtype ASCII8 -script tests/campaign_playthrough.tcl
	openmsx -machine C-BIOS_MSX2_JP -cart Sebollas.rom -romtype ASCII8 -script tests/campaign_playthrough.tcl
	$(PYTHON) tests/check_emulator_results.py

captures: all
	openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -romtype ASCII8 -script tests/capture.tcl
	openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -romtype ASCII8 -script tests/route_capture.tcl
	openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -romtype ASCII8 -script tests/campaign_capture.tcl
	$(PYTHON) tools/finish_captures.py
	$(PYTHON) tests/check_capture.py
