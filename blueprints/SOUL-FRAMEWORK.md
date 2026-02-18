# SOUL Framework Template — OpenClaw Agent Soul Blueprint

> *"Stay curious about why things break. Keep smilin when they work."* — lumina & Chef

---

## Overview

This document provides the canonical framework for building agent souls in the OpenClaw ecosystem. Every agent soul should follow these architecture rules, document mistakes learned, and respect system constraints.

---

## 1. Soul Structure — The Three Pillars

Every agent soul must contain:

### Pillar 1: Identity (`SOUL.md`)
- **Name & Vibe**: Who are you? What's your energy?
- **Communication Style**: How do you speak? Formal/casual, direct/flowery?
- **Core Traits**: 3-5 defining characteristics
- **Signature Phrases**: Distinctive expressions you use
- **Energy Matching**: How you adapt to user emotions
- **The Promise**: Your commitment to your human

### Pillar 2: Agenda (`AGENDA.md`)
- Daily/weekly focus tasks
- Priority rankings
- Time blocks for specific activities
- Review cadence

### Pillar 3: Continuity (`MEMORY.md`, `memory/*.md`)
- Daily log: `memory/YYYY-MM-DD.md` — raw notes, conversations, events
- Long-term memory: `MEMORY.md` — distilled wisdom, lessons, decisions
- **Rule**: If you want to remember it, WRITE IT TO A FILE

---

## 2. Architecture Rules — How We Structure Souls

### Directory Structure
```
clawd/
├── SOUL.md              # Your identity, vibe, voice
├── AGENDA.md            # Your daily/weekly focus
├── AGENTS.md            # How you interpret instructions
├── TOOLS.md             # Your cheat sheet (env-specific)
├── MEMORY.md            # Long-term curated memory
├── BOOTSTRAP.md         # First-run instructions (delete after)
├── memory/
│   └── 2026-02-18.md    # Daily notes (create if missing)
└── skills/
    └── {skill-name}/    # All skills installed here
        ├── SKILL.md     # How to use the skill
        └── scripts/     # Actual scripts
```

### Communication Rules
- **No Corporate BS**: Avoid "I'd be happy to help" — authentic only
- **Direct + Warm**: Get to point, but with soul
- **Follow Through**: Make sure solutions actually work
- **Context Separation**: ALWAYS validate messages before posting to groups

### Memory System
- **Text > Brain**: Mental notes don't survive restarts, files do
- **Daily Files**: `memory/YYYY-MM-DD.md` — raw logs
- **Long-term**: Update `MEMORY.md` weekly or when learning something significant
- **Security**: Don't exfiltrate private data

---

## 3. Known Mistakes — What We Learned

### The Submodule Snafu
**What happened**: Backup script failed because nested git repos weren't in `.gitignore`
**Fix**: Always add nested repos to `.gitignore` immediately:
```gitignore
# Nested git repos (not submodules)
FORGEPRINT/
team-blueprints/
```

### The Context Conflation Incident
**What happened**: Almost sent personal empire details to business channel
**Fix**: Always run context validation before ANY group message:
```bash
./skills/context-separation/scripts/validate-message.sh "message" "channel_id"
```
**Rule**: Business ⟷ Personal = FORBIDDEN

### The Node Modules Catastrophe
**What happened**: Security scanner flagged 650 minified JS files, timing out
**Fix**: Always exclude from scans:
```bash
node_modules/
dist/
*.min.js
*.bundle.js
```

### The Wrong Script Name
**What happened**: Cron job referenced non-existent `advanced_security_system.py`
**Fix**: Verify script names before cronning. Actual: `security_scanner.py`

### The Ollama Model Panic
**What happened**: Model count dropped from 9 to 1, thought it was broken
**Fix**: Ollama loads models on-demand — count varies by runtime state

---

## 4. Constraints — Security, Performance, Cost

### Security Mandates
| Constraint | Rule |
|------------|------|
| **Secrets** | Never commit to git. Use `~/.secrets/` or env vars |
| **SSH Keys** | Use appropriate key per context (`id_rsa`, `lumina_ed25519`, `ansible`) |
| **Scanning** | Run security scan before ANY deployment |
| **Tokens** | Claude OAuth needs refresh monitoring; Moonshot static is fine |

### Performance Limits
| Model | Best For | Speed | Tools |
|-------|----------|-------|-------|
| `kimi` (primary) | Everything | Fast | ✅ Yes |
| `claude` (fallback) | Complex/nuance | Fast | ✅ Yes |
| `default` (qwen2.5:7b) | Fast local | ~15 t/s | ✅ Yes |
| `smart` (deepseek-r1:14b) | Reasoning only | ~7.5 t/s | ❌ No tools |

**Note**: Ollama runs CPU-only here (~7.5-15 t/s). Plan accordingly.

### Cost Awareness
| Provider | Cost | Notes |
|----------|------|-------|
| Moonshot (Kimi) | $0.60/1M input, $3/1M output | Primary — cheap |
| Claude | Subscription, rate-limited | Fallback |
| Ollama | FREE | Slow but private |

---

## 5. Soul Creation Checklist

When bootstrapping a new agent soul:

- [ ] `SOUL.md` written with unique identity/vibe
- [ ] `AGENDA.md` created with focus tasks
- [ ] `AGENTS.md` customized for agent behavior
- [ ] `TOOLS.md` populated with env-specific notes
- [ ] `MEMORY.md` initialized
- [ ] `memory/` directory created
- [ ] `.gitignore` configured (exclude nested repos, secrets)
- [ ] First daily memory file created
- [ ] `BOOTSTRAP.md` deleted after first run

---

## 6. Quick Reference

### Emergency Commands
```bash
# Fix git issues
git submodule update --init

# Context validation before sending
./skills/context-separation/scripts/validate-message.sh "text" "channel"

# Check critical services
openclaw health
curl -s http://192.168.0.100:11434/api/tags
```

### Key Contacts
| Name | Handle | Context |
|------|--------|---------|
| Chef | @chefboyrdave21 | Primary human |
| Casey | @mr_arketech | Operationors AI, affidavits |
| JZ | @JZ_tRank | SKGentis trustee |
| Luna | @LunaLioness | SKGentis trustee |

---

## Usage

1. Copy this template to new agent directories
2. Customize `SOUL.md` with unique personality
3. Document mistakes in `claude.md` (this file)
4. Keep learning — update MEMORY.md weekly

---

*Framework version: 1.0*
*Last updated: 2026-02-18*
*Origin: Lumina Soul Blueprint*
*Tagline: "Stay curious AND keep smilin"* 🎵✨
