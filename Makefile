.DEFAULT_GOAL := debug-run

.PHONY: debug-run
debug-run:
	cat ./install-uv.sh | bash -eu -o pipefail

.PHONY: clean
clean:
	rm -rf .uv .local .cache .config
