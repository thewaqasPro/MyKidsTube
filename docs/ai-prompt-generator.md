# Project-Aware AI Prompt Generator Guide

This guide explains how to use, maintain, and integrate the standalone **MyKidsTube Project-Aware AI Prompt Generator** ([`ai-prompt-generator.html`](../ai-prompt-generator.html)) and its companion source-of-truth context document ([`AI_PROJECT_CONTEXT.md`](../AI_PROJECT_CONTEXT.md)).

---

## 1. File Locations & Rationale

Both files are located in the **project root** alongside `README.md`, `DESIGN.md`, and `Makefile`:
- [`ai-prompt-generator.html`](../ai-prompt-generator.html): Self-contained, zero-dependency HTML/CSS/JS application.
- [`AI_PROJECT_CONTEXT.md`](../AI_PROJECT_CONTEXT.md): Version-controlled structured project context covering all four monorepo targets (`apps/portal`, `apps/mobile`, `apps/mobile-android`, `apps/server`) and `scripts/`.

**Why Project Root?**
Because MyKidsTube is a multi-app monorepo (`apps/portal`, `apps/mobile`, `apps/mobile-android`, `apps/server`), placing `ai-prompt-generator.html` and `AI_PROJECT_CONTEXT.md` at the repository root gives developers and AI agents a single cross-project entry point without coupling the tool to any single sub-application's build pipeline.

---

## 2. How to Open & Use the Generator

### Option A: Open Directly in Any Browser (Zero Setup / Offline)
Double-click `ai-prompt-generator.html` in Finder/Explorer or run:
```bash
open ai-prompt-generator.html
```
Because the verified `AI_PROJECT_CONTEXT.md` snapshot is pre-embedded inside `ai-prompt-generator.html`, the generator works **100% offline** over `file://` with zero server setup.

### Option B: Serve Locally Over HTTP (Enables 1-Click `fetch` Reload)
If you want the **"Reload via HTTP"** button to automatically fetch the latest `./AI_PROJECT_CONTEXT.md` from disk without opening a file picker:
```bash
python3 -m http.server 8090
# Then open http://localhost:8090/ai-prompt-generator.html
```

### Step-by-Step Workflow
1. **Paste Task Input (Section 1):** Paste a raw voice transcript, bug report, feature idea, or refactoring request into the main text area (or click **Ex A**, **Ex B**, **Ex C**, or **Ex D** to test built-in presets).
2. **Choose Task Type & Target AI Agent:**
   - Leave **Task Type** on `Automatic detection (Default)` or select a specific type (`New feature`, `Bug fix`, `Refactoring`, `Code review`, `Research and investigation`, `Performance optimization`, `Security audit`, `Documentation`, `General task`).
   - Select your **Target AI Agent** (`Generic AI agent`, `ChatGPT`, `Claude / Claude Code`, `Cursor`, `Windsurf`, `GitHub Copilot`, or `Custom agent`).
   - Toggle **"Target agent has direct access to this repository's files"** depending on whether you are pasting into a web chat (unchecked) or an IDE agent with workspace access (checked).
3. **Click "Generate Prompt":**
   - Review the structured 12-section prompt in the right-hand viewer.
   - Click **Show Included Context** to inspect the exact project context block embedded in Section 3.
   - Click **Edit Generated Prompt** if you want to tweak any section manually before copying.
   - Click **Copy Prompt**, **Export .md**, or **Export .txt**.

---

## 3. How to Update `AI_PROJECT_CONTEXT.md`

When the repository architecture, database schema, or package versions change:
1. Edit [`AI_PROJECT_CONTEXT.md`](../AI_PROJECT_CONTEXT.md) in your code editor and update the `Last Reviewed` date at the top.
2. To use the updated file in `ai-prompt-generator.html`:
   - Click **Import Context File...** in Section 3 and select `AI_PROJECT_CONTEXT.md` from disk (works in both `file://` and `http://` modes), **or**
   - Edit the context fields directly in Section 3 of the HTML UI and click **Export Updated `AI_PROJECT_CONTEXT.md`** to download the updated Markdown file, then save it over the repository's `AI_PROJECT_CONTEXT.md`.
3. To include extra documentation for a specialized task (for example, `docs/api-reference.md` or `apps/mobile-android/PARITY-ANDROID.md`), click **+ Append Supplemental Doc...** in Section 3.

---

## 4. Enabling Mode B (AI-Enhanced Prompt Generation) & Automation Integrations

By default, the generator runs in **Mode A (Offline Deterministic Template Mode)**, which requires no internet connection or API keys.

**Mode B (AI-Enhanced Mode)** allows you to connect an LLM backend proxy or an automation webhook (such as **Integrately**, **n8n**, **Zapier**, or a custom **Cloudflare Worker** endpoint) to perform deeper LLM reasoning over your task input and project context.

### Security Rule: Never Put API Keys in `ai-prompt-generator.html`
Client-side HTML/JS must never contain `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `GEMINI_API_KEY`. Always store API keys in server-side environment variables (e.g., Cloudflare Worker secrets via `wrangler secret put` or a local backend `.env`).

### Request & Response Contract for Mode B
When you switch to **Mode B**, enter an endpoint URL, check the **Explicit Consent** checkbox, and click **Generate Prompt**, the browser sends an HTTP `POST` request with `Content-Type: application/json`:

#### Outbound Request Payload (`POST`)
```json
{
  "schema_version": "1.0",
  "timestamp": "2026-10-13T00:00:00.000Z",
  "provider_profile": "gemini",
  "target_agent": "Cursor",
  "has_repo_access": true,
  "task_type": "New feature",
  "raw_task_input": "Add a new filter to the product catalog and keep the existing design.",
  "detected_subsystems": [
    "Web Portal & Edge API (`apps/portal`)",
    "Flutter Mobile (`apps/mobile`)"
  ],
  "relevant_files": [
    "apps/portal/src/components/CategoryPills.tsx",
    "apps/portal/src/components/KidsPortal.tsx"
  ],
  "project_context": {
    "name": "MyKidsTube (KidsTube Monorepo)",
    "last_reviewed": "2026-10-13",
    "summary": "...",
    "tech_stack": "...",
    "constraints": "...",
    "full_context_markdown": "..."
  },
  "deterministic_baseline_prompt": "# AI Agent Task Specification..."
}
```

#### Expected JSON Response (`200 OK`)
Your backend proxy or webhook should return JSON with a `prompt` (or `enhancedPrompt` / `output`) string:
```json
{
  "prompt": "# AI Agent Task Specification — MyKidsTube\n\n## 1. Agent Role\n..."
}
```

### Integrating with Integrately / Webhooks
1. Note that cloud automation platforms (such as Integrately) **cannot access local files on your computer**.
2. Instead, `ai-prompt-generator.html` packages both the `raw_task_input`, `project_context`, and `deterministic_baseline_prompt` into a single self-contained JSON payload.
3. In Integrately (or n8n/Make):
   - Create a **Webhook Trigger** and paste the webhook URL into **Section 2 (Backend Proxy / Webhook URL)** of `ai-prompt-generator.html`.
   - Click **Preview Outbound JSON Payload** in Section 2 to inspect the exact fields available for mapping.
   - Check the **Explicit Consent** box and click **Generate Prompt** to send the payload to your webhook.
   - Note: If your Integrately webhook uses a restricted CORS policy in the browser, route the request through a local proxy or an Astro API route (e.g. `/api/ai/prompt-enhance`).

---

## 5. Limitations & Security Considerations

1. **`file://` Browser Security Restrictions:** Modern browsers block `fetch('./AI_PROJECT_CONTEXT.md')` when an HTML page is opened directly from disk via `file://`. To solve this cleanly, `ai-prompt-generator.html` embeds the verified context by default and provides an `<input type="file">` picker (**Import Context File...**) that works in all browsers without a server.
2. **No Silent File Overwrites:** Browser JavaScript cannot silently overwrite `AI_PROJECT_CONTEXT.md` in your git repository. Exporting produces a downloaded file that you review and commit under version control.
3. **Offline Mode vs. LLM Reasoning:** Mode A is a deterministic rule and template engine—it maps keywords to MyKidsTube subsystems (`apps/portal`, `apps/mobile`, `apps/mobile-android`, `apps/server`) and injects verified project rules, clearly labeling generic recommendations as `[Suggested — Verify Against Task Scope]`.
4. **Automatic Credential Redaction:** The generator scans both task input and context for common credential patterns (`sk-...`, `AIza...`, `ghp_...`, `Bearer <token>`, PEM private keys) and replaces them with `[REDACTED_SENSITIVE_CREDENTIAL]` before rendering the prompt.
5. **Safe DOM Rendering & Transparent LocalStorage:** User input is rendered strictly via `textContent` / `value` (never `innerHTML`), preventing XSS injection. Browser `localStorage` is disabled by default unless the user explicitly checks **"Remember edits in browser storage"**, and can be wiped at any time via **"Erase Saved Browser Data"**.
