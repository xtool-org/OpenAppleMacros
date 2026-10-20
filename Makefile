OBJCOPY ?= llvm-objcopy
ARCHS ?= x86_64 aarch64

MACRO_MODULES = $(sort $(notdir $(wildcard Sources/*Macros)))

all: umbrella-check
	@$(MAKE) build-archs

smoke: umbrella-check
	swift build --product OpenAppleMacrosServer

docker:
	@+$(MAKE) docker-build
	@+$(MAKE) docker-run

docker-build:
	docker build -t openapplemacros:latest .

docker-run:
	@mkdir -p output
	docker run --rm -v .:/src -v ./.build/docker:/src/.build openapplemacros:latest make ARCHS="$(ARCHS)"

docker-smoke:
	docker build . --build-arg SMOKE=1 -t openapplemacros:smoke
	docker run --rm -v .:/src -v ./.build/docker:/src/.build openapplemacros:smoke make smoke

build-archs: $(addprefix build-arch-,$(ARCHS))

build-arch-%: build-info build-server-%
	@rm -f output/OpenAppleMacrosServer-$*.tar.gz
	@mkdir -p output
	COPYFILE_DISABLE=1 tar czf output/OpenAppleMacrosServer-$*.tar.gz \
		-C $(abspath tmp/info) info.json \
		-C $(abspath tmp/server-$*) OpenAppleMacrosServer

build-info:
	@rm -rf tmp/info
	@mkdir -p tmp/info
	@{ \
		printf '{"plugins":['; \
		separator=''; \
		for module in $(MACRO_MODULES); do \
			printf '%s"%s"' "$$separator" "$$module"; \
			separator=','; \
		done; \
		printf ']}\n'; \
	} > tmp/info/info.json

build-server-%:
	@rm -rf tmp/server-$*
	@mkdir -p tmp/server-$*
	swift build --product OpenAppleMacrosServer --swift-sdk $*-swift-linux-musl -c release
	$(OBJCOPY) --strip-all .build/out/Products/Release-staticlinux-$*/OpenAppleMacrosServer tmp/server-$*/OpenAppleMacrosServer

UMBRELLA_FILE = Sources/OpenAppleMacrosKit/Generated/All.swift
UMBRELLA_TMP = tmp/oam-generated/Umbrella.swift

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
	@echo '// Generated with `make umbrella`. Do not modify manually.' > $(UMBRELLA_TMP)
	@echo >> $(UMBRELLA_TMP)
	@echo 'import OpenAppleMacrosBase' >> $(UMBRELLA_TMP)
	@$(foreach mod,$(MACRO_MODULES),echo 'import $(mod)' >> $(UMBRELLA_TMP);)
	@echo >> $(UMBRELLA_TMP)
	@echo 'var allMacros: [[any Macro.Type]] { [' >> $(UMBRELLA_TMP)
	@$(foreach mod,$(MACRO_MODULES),echo '    $(mod).all,' >> $(UMBRELLA_TMP);)
	@echo '] }' >> $(UMBRELLA_TMP)
	@echo 'var allModules: [String] { [' >> $(UMBRELLA_TMP)
	@$(foreach mod,$(MACRO_MODULES),echo '    "$(mod)",' >> $(UMBRELLA_TMP);)
	@echo '] }' >> $(UMBRELLA_TMP)

clean:
	@rm -rf .build output tmp
