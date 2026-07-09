# ════════════════════════════════════════════════════════════════
#  Revivo — developer command reference
#  Run `make help` for the full list.
# ════════════════════════════════════════════════════════════════
.DEFAULT_GOAL := help
.PHONY: help bootstrap infra-deploy infra-diff infra-destroy seed \
        app-get app-run app-web app-build-apk analyze test lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# ─── Infrastructure (AWS CDK, Python) ───────────────────────────
bootstrap: ## One-time CDK bootstrap of the AWS account/region
	cd infra && python -m venv .venv && . .venv/bin/activate && \
	 pip install -r requirements.txt && cdk bootstrap

infra-deploy: ## Deploy all backend stacks to AWS
	cd infra && . .venv/bin/activate && cdk deploy --all --require-approval never

infra-diff: ## Show pending infrastructure changes
	cd infra && . .venv/bin/activate && cdk diff

infra-destroy: ## Tear down all deployed stacks
	cd infra && . .venv/bin/activate && cdk destroy --all

# ─── Seed data ──────────────────────────────────────────────────
seed: ## Load demo accounts, listings, rescues, and orders (needs backend/.venv)
	cd backend && . .venv/bin/activate && \
	 DEMO_PASSWORD=$${DEMO_PASSWORD:-TestPass123} python scripts/seed_users.py && \
	 python scripts/seed_listings.py && \
	 python scripts/seed_rescues.py && \
	 python scripts/seed_orders.py

# ─── Flutter app ────────────────────────────────────────────────
app-get: ## Fetch Flutter dependencies
	cd app && flutter pub get

app-run: ## Run the app on a connected device/emulator
	cd app && flutter run

app-web: ## Run the app in a browser
	cd app && flutter run -d chrome

app-build-apk: ## Build a release Android APK
	cd app && flutter build apk --release

# ─── Quality gates ──────────────────────────────────────────────
analyze: ## Static analysis for the Flutter app
	cd app && flutter analyze

lint: ## Lint backend + infra Python
	ruff check backend infra || true

test: ## Run backend unit tests
	cd backend && python -m pytest -q || true
