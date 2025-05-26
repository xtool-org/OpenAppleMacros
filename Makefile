STRIP ?= strip

MACRO_MODULES = $(notdir $(wildcard Sources/*Macros))

all: umbrella-check
	swift build --product OpenAppleMacrosServer --swift-sdk aarch64-swift-linux-musl -c release
	$(STRIP) .build/aarch64-swift-linux-musl/release/OpenAppleMacrosServer
	@rm -rf output
	@mkdir -p output
	@cp -a .build/aarch64-swift-linux-musl/release/OpenAppleMacrosServer output/swift-plugin-server

UMBRELLA_FILE = Sources/OpenAppleMacrosServer/Generated/All.swift
UMBRELLA_TMP = .build/oam-generated/Umbrella.swift

umbrella: umbrella-tmp
	@cp -a $(UMBRELLA_TMP) $(UMBRELLA_FILE)
	@echo "Found modules: $(MACRO_MODULES)"

umbrella-check: umbrella-tmp
	@if ! cmp -s $(UMBRELLA_TMP) $(UMBRELLA_FILE); then \
		echo "Umbrella file is out of date. Run 'make umbrella' to update it."; \
		exit 1; \
	fi

umbrella-tmp:
	@mkdir -p $(dir $(UMBRELLA_TMP))
	@echo '// Generated with `make umbrella`. Do not modify manually.'$$'\n' > $(UMBRELLA_TMP)
	@$(foreach mod,$(MACRO_MODULES),echo 'import $(mod)' >> $(UMBRELLA_TMP);)
	@echo $$'\n''let allMacros = [' >> $(UMBRELLA_TMP)
	@$(foreach mod,$(MACRO_MODULES),echo '    $(mod).all,' >> $(UMBRELLA_TMP);)
	@echo ']' >> $(UMBRELLA_TMP)
