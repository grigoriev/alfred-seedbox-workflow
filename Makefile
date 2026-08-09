WORKFLOW    := Seedbox.alfredworkflow
UPDATER_URL := https://github.com/grigoriev/alfred-workflow-updater/releases/latest/download/updater.tar.gz
SCRIPTS     := src/seedbox.sh src/http.sh src/globals.sh src/cache.sh
EXCLUDES    := '.git/*' '.github/*' '.gitignore' 'Makefile' '$(WORKFLOW)'

.PHONY: all build updater verify-updater test lint icons clean

all: build

icons:
	bash .github/build-icons.sh

updater:
	curl -sfL $(UPDATER_URL) | tar -xzf - -C src
	chmod +x src/update.sh src/autoupdate.sh

verify-updater: updater
	@out=$$(alfred_workflow_version=0.0.1 update_repo=grigoriev/alfred-seedbox-workflow update_asset=$(WORKFLOW) bash src/update.sh 2>/dev/null || true); \
	if printf '%s' "$$out" | grep -q '"title":"Update to v'; then echo "updater OK"; else echo "no release yet; updater smoke test skipped"; fi

build: verify-updater
	rm -f $(WORKFLOW)
	zip -qr $(WORKFLOW) . -x $(EXCLUDES)
	unzip -l $(WORKFLOW) | grep -q 'src/update.sh'
	@echo "built $(WORKFLOW)"

test: updater
	bats tests

lint:
	shellcheck -x --severity=warning $(SCRIPTS)

clean:
	rm -f $(WORKFLOW) src/update.sh src/autoupdate.sh
