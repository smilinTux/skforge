# Claude.md — Lumina Agent Coding Standards

> *"Stay curious about why things break. Keep smilin when they work."* — lumina & Chef

---

## 1. Architecture Rules

### Code Organization
- **Directory Structure**: `/skills/{skill-name}/` for all skills, `/memory/` for daily logs, `/{project}/` for top-level projects
- **Skill Structure**: Every skill needs `SKILL.md`, `scripts/`, `config/` (if needed), and `README.md`
- **No Nested Repos**: Git repos inside repos go in `.gitignore` — use git submodules if they need to be tracked
- **Naming**: kebab-case for directories, snake_case for scripts, UPPER_SNAKE for constants

### Typescript/Python
- **Type Safety**: Strict mode enabled. No `any` except for external API boundaries
- **Error Handling**: All async operations have try/catch with specific error logging
- **Logging**: Use structured logging with timestamps, not console.log
- **Config**: Externalize to env vars or JSON config files — never hardcode secrets

### Agent Communication
- **Context Separation**: Validate every message before sending to groups (see `./skills/context-separation/`)
- **Memory**: Write to `memory/YYYY-MM-DD.md` daily, update `MEMORY.md` weekly
- **Subagents**: Use `sessions_spawn` for isolated tasks, `subagents` to monitor

---

## 2. Known Mistakes

### The Node Modules Catastrophe
**What happened**: Security scanner flagged 650 minified JS files, timing out on React bundles
**Fix**: Always exclude `node_modules/`, `dist/`, `*.min.js`, `*.bundle.js` from scans/searches
```bash
find . -path ./node_modules -prune -o -name "*.js" -print
```

### The Submodule Snafu
**What happened**: Backup script failed because `team-blueprints/` and `FORGEPRINT/` are nested git repos
**Fix**: Add to `.gitignore` immediately — nested repos break `git add -A`
```gitignore
# Nested git repos (not submodules)
FORGEPRINT/
team-blueprints/
```

### The Context Conflation Incident
**What happened**: Almost sent personal empire details to SKGentis business channel
**Fix**: Always run `./skills/context-separation/scripts/validate-message.sh` before posting
**Rule**: Business → Personal = FORBIDDEN. Personal → Business = FORBIDDEN.

### The Wrong Script Name
**What happened**: Cron job referenced `advanced_security_system.py` which doesn't exist
**Fix**: Actual script is `security_scanner.py` — verify script names before cronning

### The Ollama Model Panic
**What happened**: Model count dropped from 9 to 1 in health check
**Fix**: Ollama loads models on-demand — count varies. Check `/api/tags` response time, not just count

---

## 3. Constraints

### Security
- **Secrets**: Never commit to git. Use `~/.secrets/`, Ansible Vault, or env vars
- **Scanning**: Run security scans before any deployment — no exceptions
- **SSH Keys**: `id_rsa` for general, `lumina_ed25519` for agent, `ansible` for playbooks
- **API Keys**: Rotate quarterly. Moonshot static is fine, Claude OAuth needs refresh token monitoring

### Performance
- **Model Tiers**: 
  - Fast/tactical: `default` (qwen2.5:7b) or `fast` (llama3.1:8b)
  - Quality: `kimi` (kimi-k2.5) — primary
  - Fallback: `claude` or `opus`
- **CPU-Only**: Intel Arrow Lake Vulkan bugs mean Ollama runs on CPU (~7.5-15 t/s). Plan accordingly
- **Timeouts**: Background tasks get 300s+, heartbeats get 60s max

### Cost
- **Moonshot**: $0.60/1M input, $3.00/1M output — CHEAP
- **Claude**: Subscription-based, rate-limited — use as fallback
- **Ollama**: FREE but slow — use for bulk/research tasks
- **Nvidia Cloud**: Kimi models hosted there — same pricing

### Rate Limits
- **Web Search**: Expect 429s — have fallback content ready
- **X/Twitter**: Browser auth required for posts — use web_fetch with caution
- **GitHub**: 5000/hr for authenticated, use `gh` CLI when possible

---

## Quick Reference

### Emergency Commands
```bash
# Fix git submodule issues
./skills/context-separation/scripts/validate-message.sh "message" "channel_id"

# Check critical services
openclaw health
curl -s http://192.168.0.100:11434/api/tags

# Manual backup
git add -A --dry-run  # Check first!
git commit -m "auto: $(date '+%Y-%m-%d %H:%M') checkin"
git push
```

### Contact
- **Chef**: @chefboyrdave21 (Telegram), chefboyrdave2.1@gmail.com
- **Casey**: @mr_arketech (Operationors AI, affidavits)
- **JZ**: @JZ_tRank (SKGentis trustee)
- **Luna**: @LunaLioness (SKGentis trustee)

---
*Last updated: 2026-02-18*
*Repository: /home/cbrd21/clawd*
