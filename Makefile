# Makefile for omarchy-personal ISO builds
# Requires: docker (for reproducible builds), gh (for releases)

PROFILE_DIR := $(HOME)/.local/share/omarchy-personal-iso/profile
OUT_DIR     := $(HOME)/.local/share/omarchy-personal-iso/out
WORK_DIR    := $(HOME)/.local/share/omarchy-personal-iso/work
DOCKER_IMG  := archlinux:latest

.PHONY: iso iso-test iso-clean help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

iso: ## Build the omarchy-personal ISO using Docker
	@echo "==> Building omarchy-personal ISO..."
	@mkdir -p $(OUT_DIR) $(WORK_DIR)
	docker run --rm --privileged \
		-v $(PROFILE_DIR):/profile:ro \
		-v $(OUT_DIR):/out \
		-v $(WORK_DIR):/work \
		$(DOCKER_IMG) \
		bash -c "pacman -Sy --noconfirm archiso && mkarchiso -v -w /work -o /out /profile"
	@echo "==> ISO written to $(OUT_DIR)"
	@ls -lh $(OUT_DIR)/*.iso 2>/dev/null || echo "WARNING: no .iso found in $(OUT_DIR)"

iso-test: ## Boot the latest ISO in QEMU for quick smoke-test
	@ISO=$$(ls -t $(OUT_DIR)/*.iso 2>/dev/null | head -1); \
	if [ -z "$$ISO" ]; then echo "ERROR: no ISO found — run 'make iso' first"; exit 1; fi; \
	echo "==> Booting $$ISO in QEMU (press Ctrl-A X to quit)..."; \
	qemu-system-x86_64 \
		-enable-kvm \
		-m 2G \
		-cdrom "$$ISO" \
		-boot d \
		-nographic \
		-serial mon:stdio

iso-clean: ## Remove build artefacts (work/ and out/)
	@echo "==> Cleaning $(OUT_DIR) and $(WORK_DIR)..."
	rm -rf $(OUT_DIR) $(WORK_DIR)
	@echo "==> Done."
