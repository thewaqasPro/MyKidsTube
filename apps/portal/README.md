# Astro Starter Kit: Minimal

```sh
pnpm create astro@latest -- --template minimal
```

> 🧑‍🚀 **Seasoned astronaut?** Delete this file. Have fun!

## 🚀 Project Structure

Inside of your Astro project, you'll see the following folders and files:

```text
/
├── public/
├── src/
│   └── pages/
│       └── index.astro
└── package.json
```

Astro looks for `.astro` or `.md` files in the `src/pages/` directory. Each page is exposed as a route based on its file name.

There's nothing special about `src/components/`, but that's where we like to put any Astro/React/Vue/Svelte/Preact components.

Any static assets, like images, can be placed in the `public/` directory.

## 🧞 Commands

All commands are run from the root of the project, from a terminal:

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `pnpm install`             | Installs dependencies                            |
| `pnpm dev`             | Starts local dev server at `localhost:4321`      |
| `pnpm build`           | Build your production site to `./dist/`          |
| `pnpm preview`         | Preview your build locally, before deploying     |
| `pnpm astro ...`       | Run CLI commands like `astro add`, `astro check` |
| `pnpm astro -- --help` | Get help using the Astro CLI                     |

## 🗄️ Database & Migrations

KidsTube uses Cloudflare D1 for catalog, device pairing, and parent session storage.

### Running Migrations

Migration files are located in `migrations/`:
- `0001_admin_settings.sql` — Settings key-value store (parent PIN)
- `0002_watch_events.sql` — Watch analytics telemetry
- `0003_parent_sessions.sql` — 256-bit parent session tokens

**Apply migrations locally:**
```sh
npx wrangler d1 migrations apply kidstube-db --local
```

**Apply migrations to production D1:**
```sh
npx wrangler d1 migrations apply kidstube-db --remote
```

**Initialize fresh database from schema:**
```sh
npx wrangler d1 execute kidstube-db --local --file=../../d1_ready.sql
```

## 👀 Want to learn more?

Feel free to check [our documentation](https://docs.astro.build) or jump into our [Discord server](https://astro.build/chat).
