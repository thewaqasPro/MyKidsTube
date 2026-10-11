.PHONY: help server server-down server-logs portal portal-build portal-deploy mobile mobile-apk test sync-export sync-upload

help:
	@echo "MyKidsTube Monorepo Commands:"
	@echo "  make portal          - Run frontend portal locally (Astro SSR)"
	@echo "  make portal-build   - Build frontend portal bundle"
	@echo "  make portal-deploy   - Deploy portal to Cloudflare Workers"
	@echo "  make server          - Start VPS Nginx static media streamer"
	@echo "  make server-down     - Stop VPS Nginx container"
	@echo "  make server-logs     - View live container logs"
	@echo "  make sync-export     - Export pending wishlist links for HandBrake"
	@echo "  make sync-upload     - Rsync encoded MP4s to 80GB VPS storage"
	@echo "  make mobile          - Run Flutter kid tablet app"
	@echo "  make mobile-apk      - Build release Android APK"
	@echo "  make test            - Run Flutter unit & widget tests"

portal:
	cd apps/portal && pnpm dev

portal-build:
	cd apps/portal && pnpm build

portal-deploy:
	cd apps/portal && pnpm build && npx wrangler deploy

server:
	docker compose up -d

server-down:
	docker compose down

server-logs:
	docker compose logs -f

sync-export:
	./scripts/sync-mykidstube.sh export

sync-upload:
	./scripts/sync-mykidstube.sh upload

mobile:
	cd apps/mobile && flutter run

mobile-apk:
	./scripts/build-apk.sh

test:
	cd apps/mobile && flutter test
