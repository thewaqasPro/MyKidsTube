.PHONY: help server server-down server-logs mobile mobile-apk test

help:
	@echo "KidsTube Monorepo Commands:"
	@echo "  make server        - Start Docker media server (Nginx + FastAPI + Ingestion)"
	@echo "  make server-down   - Stop Docker media server"
	@echo "  make server-logs   - Follow live server logs"
	@echo "  make mobile        - Run Flutter app (auto-detects emulator/device)"
	@echo "  make mobile-apk    - Build release Android APK"
	@echo "  make test          - Run mobile unit and widget tests"

server:
	docker compose up -d

server-down:
	docker compose down

server-logs:
	docker compose logs -f

mobile:
	cd apps/mobile && flutter run

mobile-apk:
	cd apps/mobile && flutter build apk --release

test:
	cd apps/mobile && flutter test
