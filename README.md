# ZoneWise Agent Teams — Multi-Agent Build Orchestrator

Adapted from [Cole Medin's build-with-agent-team skill](https://github.com/coleam00/context-engineering-intro/tree/main/use-cases/build-with-agent-team) for the ZoneWise/BidDeed.AI agentic ecosystem. Optimized for county scraper builds, multi-county expansion, and foreclosure auction pipeline development.

## What This Does

Spawns a team of Claude Code instances that work together in tmux split panes to build ZoneWise components. Uses **contract-first spawning** to prevent integration mismatches — upstream agents (Schema) publish data contracts before downstream agents (Scraper, API, UI) start building.

### Two Commands

| Command | Use Case | Default Team |
|---------|----------|-------------|
| `/build-with-agent-team [plan] [n]` | Any ZoneWise build from a plan doc | Auto-determined |
| `/build-county-scraper [county] [url]` | Fast-track county scraper build | 3 agents (Schema + Scraper + Test) |

## Prerequisites

### 1. Install tmux (WSL)

You're on Windows with WSL. In your WSL terminal:

```bash
sudo apt update && sudo apt install tmux -y
tmux -V  # Verify: should show tmux 3.x
```

### 2. Enable Agent Teams

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or export in `~/.bashrc`:
```bash
echo 'export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1' >> ~/.bashrc
source ~/.bashrc
```

### 3. Verify Claude Code

```bash
claude --version  # Should be latest
```

## Installation

### Option A: Global (recommended — works across all repos)

```bash
# Skill
cp -r skill/SKILL.md ~/.claude/skills/build-with-agent-team/SKILL.md

# Commands
cp commands/build-county-scraper.md ~/.claude/commands/build-county-scraper.md
```

### Option B: Per-repo (zonewise-modal only)

```bash
cd ~/zonewise-modal  # or wherever the repo is
mkdir -p .claude/skills/build-with-agent-team .claude/commands

cp skill/SKILL.md .claude/skills/build-with-agent-team/SKILL.md
cp commands/build-county-scraper.md .claude/commands/build-county-scraper.md
```

## Usage

### Build a County Scraper (Fast Track)

```bash
# Let it auto-construct the plan
/build-county-scraper orange

# With explicit URL
/build-county-scraper orange https://orange.realforeclose.com

# Duval County
/build-county-scraper duval https://duval.realforeclose.com
```

This auto-generates a complete plan and spawns a 3-agent team:
1. **Schema Agent** — verifies FIPS code, checks Supabase schema, produces data contract
2. **Scraper Agent** — analyzes DOM, builds AgentQL scraper matching the contract
3. **Test Agent** — builds tests, updates master_scraper.yml, validates integration

### Build Any Feature (General)

Write a plan doc (see `example-plans/` for templates), then:

```bash
# Auto-determine team size
/build-with-agent-team ./plans/my-feature.md

# Specify team size
/build-with-agent-team ./plans/my-feature.md 4
```

## Contract-First Architecture

The key innovation (from Cole Medin's design) adapted for our domain:

```
┌─────────────────────┐
│     Lead Agent      │ ← Coordinator only (Delegate Mode)
│  Verifies contracts │
│  Relays to agents   │
└──────────┬──────────┘
           │
    ┌──────┴──────────────────────────────┐
    │ Phase 1: Contracts (Sequential)     │
    │                                     │
    │  Schema Agent ──contract──► Lead    │
    │  Lead verifies ──forward──► Scraper │
    │  Scraper ──sample output──► Lead    │
    │  Lead verifies ──forward──► Test    │
    └──────┬──────────────────────────────┘
           │
    ┌──────┴──────────────────────────────┐
    │ Phase 2: Implementation (Parallel)  │
    │                                     │
    │  ┌─────────┐ ┌─────────┐ ┌───────┐ │
    │  │ Schema  │ │ Scraper │ │ Test  │ │
    │  │ (done)  │ │ builds  │ │builds │ │
    │  └─────────┘ └─────────┘ └───────┘ │
    └──────┬──────────────────────────────┘
           │
    ┌──────┴──────────────────────────────┐
    │ Phase 3: Validation (Lead runs E2E) │
    │  Scrape → Insert → Query → Verify   │
    └─────────────────────────────────────┘
```

## Why Not Just Sub-agents?

| Scenario | Use Sub-agents | Use Agent Teams |
|----------|---------------|-----------------|
| Research a county's DOM structure | ✅ | |
| Analyze lien priority on a case | ✅ | |
| Build a county scraper end-to-end | | ✅ |
| Build a new pipeline stage | | ✅ |
| Search AcclaimWeb for liens | ✅ | |
| Multi-county expansion sprint | | ✅ |

**Rule of thumb:** Sub-agents for isolated research. Agent Teams for coordinated builds.

## Token Cost Reality

Agent Teams uses 2-4x more tokens than single Claude Code sessions. On the Max plan with unlimited Sonnet 4.5, this is manageable. Budget guidance:

| Build Type | Agents | Est. Tokens | Max Plan Cost |
|-----------|--------|-------------|---------------|
| County scraper | 3 | ~600K | $0 (unlimited) |
| Full feature | 4-5 | ~1.5M | $0 (unlimited) |
| 67-county expansion | 3 × 67 | ~40M | $0 (unlimited) |

Stay on **Sonnet 4.5 via Claude Code Max** for all Agent Teams work.

## File Structure

```
zonewise-agent-teams/
├── skill/
│   └── SKILL.md                          # Main Agent Teams skill
├── commands/
│   └── build-county-scraper.md           # Fast-track county scraper command
├── example-plans/
│   └── orange-county-scraper-plan.md     # Template: Orange County build
├── tests/
│   └── validate-skill-install.sh         # Verify installation
└── README.md                             # This file
```

## Adapting for New Build Types

The SKILL.md is designed for county scrapers as the primary use case but handles any ZoneWise build. To add a new build type:

1. Create a plan doc in `example-plans/`
2. Define the agent team structure in the plan
3. Map the contract chain (who produces → who consumes)
4. List cross-cutting concerns and assign owners
5. Add validation commands for each agent

## Credits

- **Original skill**: [Cole Medin](https://github.com/coleam00/context-engineering-intro) — contract-first spawning pattern
- **Adaptation**: ZoneWise/BidDeed.AI team — domain-specific contracts, county scraper fast-track, Supabase integration
- **Architecture**: Anthropic Agent Teams experimental feature
