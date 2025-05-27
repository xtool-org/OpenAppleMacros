STRIP ?= strip

MACRO_MODULES = $(notdir $(wildcard Sources/*Macros))

ARCHS = x86_64 aarch64

all: umbrella-check
	@rm -rf output
	@mkdir -p output
	@$(MAKE) build-archs

smoke: umbrella-check
	swift build --product OpenAppleMacrosServer

docker:
	docker build -t openapplemacros:latest .
	docker run -v .:/src -it openapplemacros:latest make

build-archs: $(addprefix build-arch-,$(ARCHS))

build-arch-%:
	swift build --product OpenAppleMacrosServer --swift-sdk $*-swift-linux-musl -c release
	$(STRIP) .build/$*-swift-linux-musl/release/OpenAppleMacrosServer
	@cp -a .build/$*-swift-linux-musl/release/OpenAppleMacrosServer output/OpenAppleMacrosServer-$*

UMBRELLA_FILE = Sources/OpenAppleMacrosServer/Generated/All.swift
UMBRELLA_TMP = .build/oam-generated/Umbrella.swift

umbrella: umbrella-tmp
	@cp -a $(UMBRELLA_TMP) $(UMBRELLA_FILE)
	@echo "Found modules: $(MACRO_MODULES)"

umbrella-check: umbrella-tmp
	@if ! cmp -s $(UMBRELLA_TMP) $(UMBRELLA_FILE); then \
		echo "Umbrella file is out of date. Run 'make umbrella' to update it."; \
		cat $(UMBRELLA_TMP); \
		echo 'Current umbrella file:'; \
		cat $(UMBRELLA_FILE); \
		exit 1; \
	fi

umbrella-tmp:
	@mkdir -p $(dir $(UMBRELLA_TMP))
	@echo '// Generated with `make umbrella`. Do not modify manually.' > $(UMBRELLA_TMP)
	@echo >> $(UMBRELLA_TMP)
	@$(foreach mod,$(MACRO_MODULES),echo 'import $(mod)' >> $(UMBRELLA_TMP);)
	@echo >> $(UMBRELLA_TMP)
	@echo 'let allMacros = [' >> $(UMBRELLA_TMP)
	@$(foreach mod,$(MACRO_MODULES),echo '    $(mod).all,' >> $(UMBRELLA_TMP);)
	@echo ']' >> $(UMBRELLA_TMP)
