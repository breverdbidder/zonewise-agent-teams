# CLAUDE.md — Shapira Agentic Stack

> Root directive for all Claude Code sessions. Read this first. Always.

## Identity

- **Product Owner:** Ariel Shapira (20 min/day oversight max)
- **AI Architect:** Claude AI (autonomous decisions, no permission needed)
- **Agentic Engineer:** Claude Code (7-hour sessions, zero human-in-loop)
- **Repo owner:** breverdbidder (GitHub)

## Active Repos

| Repo | Purpose | Deploy |
|------|---------|--------|
| `breverdbidder/brevard-bidder-scraper` | BidDeed.AI — auction pipeline | Render.com |
| `breverdbidder/zonewise-agents` | ZoneWise — 67-county scraper agents | Render.com |
| `breverdbidder/zonewise-web` | ZoneWise — marketing site | Vercel / Cloudflare Pages |
| `breverdbidder/zonewise-desktop` | ZoneWise — desktop app | Electron |
| `breverdbidder/context-boot-mcp-server` | Context boot MCP | npm |

## Tech Stack

- **Runtime:** Node.js 20 / Python 3.11
- **Framework:** Next.js 15 (App Router), FastAPI
- **Database:** Supabase (Postgres) — `mocerqjnksmhcjzxrewo.supabase.co`
- **ORM:** Drizzle (JS) / SQLAlchemy (Python)
- **Auth:** Supabase Auth
- **Hosting:** Render.com (backend), Cloudflare Pages (frontend), Vercel (zonewise-web)
- **Orchestration:** LangGraph (multi-agent), GitHub Actions (CI/CD)
- **LLM Routing:** LiteLLM Smart Router
- **Browser Testing:** agent-browser (Vercel)
- **Unit Testing:** Vitest (JS), Pytest (Python)

## Commands

```bash
npm run dev          # Start dev server (port 3000)
npm run build        # Production build
npm run test         # Vitest unit tests (watch)
npm run test:run     # Vitest once
npm run test:e2e     # E2E with agent-browser
npm run lint         # Biome lint
npm run db:push      # Push Drizzle schema to Supabase
npm run db:studio    # Drizzle Studio

python -m pytest     # Python unit tests
uvicorn app.main:app --reload --port 8000  # FastAPI dev
```

## Project Structure (BidDeed.AI)

```
src/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Login/signup
│   ├── (dashboard)/       # Main app
│   └── api/               # API routes
├── agents/                # LangGraph agent definitions
├── scrapers/              # County auction scrapers
├── lib/                   # Shared utilities
└── types/                 # TypeScript types

.github/workflows/         # GitHub Actions (nightly pipeline, deploy)
scripts/                   # Standalone utility scripts
```

## Key Supabase Tables

| Table | Purpose |
|-------|---------|
| `multi_county_auctions` | All auction records (67 counties) |
| `historical_auctions` | Processed + analyzed auctions |
| `insights` | Agent run logs, errors, decisions |
| `claude_context_checkpoints` | Context boot MCP checkpoints |
| `master_index` | Single source of truth for all repos/files |

## Environment Variables (check `.env.example`)

```
SUPABASE_URL=https://mocerqjnksmhcjzxrewo.supabase.co
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
DATABASE_URL=postgresql://...   # Direct Postgres URL for psql
GITHUB_PAT=<from-github-secrets>
```

## Coding Conventions

- **TypeScript:** strict mode, no `any`
- **Naming:** camelCase (JS/TS), snake_case (Python/SQL)
- **Error handling:** always log to `insights` table with `status=ERROR`
- **DB writes:** use service role key, never anon key for inserts
- **Commits:** `feat:`, `fix:`, `chore:`, `docs:` prefixes
- **Never:** hardcode API keys, use Google Drive, create ZIP files

## Autonomous Rules

### Execute Without Asking:
- Bug fixes, refactors, optimizations
- GitHub Actions deployments
- Supabase read queries
- Test creation and runs
- Documentation updates
- Dependency updates
- Git commits and pushes

### Always Surface to Ariel:
- Spend >$10 on new services
- Production schema changes (migrations)
- Delete production data
- New third-party integrations (first time)
- Security / auth changes

### Escalation Format:
```
BLOCKED: [issue]. Tried: [3 attempts]. Recommend: [solution]. Approve?
```

## TODO.md Protocol (MANDATORY)

Before ANY project task:
1. Load `TODO.md` from GitHub
2. Find current unchecked task
3. Execute + verify
4. Mark `[x]` and push

## Shabbat Awareness

- No human availability Friday sunset → Saturday havdalah (Satellite Beach FL, 32937)
- Automated tasks continue unattended during Shabbat — this is fine
- Outputs queue for Havdalah review
