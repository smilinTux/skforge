# 🐧 smilinTux Ecosystem — The Full Picture

## The Stack

```
smilinTux.org QT (parent trust)
  "Helping architect our quantum future, one smile at a time."
  │
  └── smilinTux (GitHub org) — "Making Self-Hosting & Decentralized Cool Again"
       │
       ├── 🍳 SKForge              LIVE     — AI-native software recipes
       │   └── The Cookbook: blueprints for every software category
       │   └── Stack Composer: forge entire vertical stacks
       │   └── RECON: methodology to blueprint ANY software
       │
       ├── 🏗️ SKStacks                COMING   — Zero-trust infrastructure framework
       │   └── The reference kitchen: production-proven recipes in action
       │   └── Docker Swarm / K8s deployment patterns
       │   └── AI-first, data sovereign, quantum-ready security
       │
       ├── 🧠 SKMemory                LIVE     — AI memory system
       │   └── Vector + Graph memory for AI agents
       │   └── Also a SKForge recipe category!
       │
       ├── 🌟 SKyForge                LIVE     — Alignment calendar
       │
       └── 🎨 assets                  LIVE     — Brand kit, King Divad mascot
```

## The Relationship

**SKForge** = The cookbook (recipes for building software)
**SKStacks** = The restaurant (recipes put into production)

SKForge tells you HOW to build. SKStacks shows you it WORKS.

```
SKForge Recipe: "databases"
  → SKStacks runs PostgreSQL in production using these exact patterns

SKForge Recipe: "vector-databases"  
  → SKStacks runs SKVector (Qdrant) in production

SKForge Recipe: "graph-databases"
  → SKStacks runs SKGraph (FalkorDB) in production

SKForge Recipe: "container-orchestrators"
  → SKStacks runs Docker Swarm + K8s in production

SKForge Recipe: "secret-management"
  → SKStacks runs zero-trust secret injection in production

SKForge Recipe: "api-gateways"
  → SKStacks runs Traefik with mTLS in production
```

Every SKForge recipe has a battle-tested reference in SKStacks.

## SKStacks Public Release Plan

### What Ships (sanitized, open source)
- [ ] Core framework architecture (Docker Swarm patterns, stack configs)
- [ ] Deployment playbooks (Ansible, generic — no private IPs/passwords)
- [ ] Service templates (Traefik, monitoring, logging, CI/CD patterns)
- [ ] Security patterns (zero-trust networking, mTLS, RBAC)
- [ ] AI agent deployment patterns (OpenClaw, Ollama, vector/graph DB)
- [ ] Documentation (architecture decisions, runbooks, operational guides)

### What Stays Private (never ships)
- [ ] SKGentis Trust code (client-specific, NDA)
- [ ] NAMStacks tribal government code (client-specific)
- [ ] Private keys, credentials, vault passwords
- [ ] Client-specific Ansible inventories and host vars
- [ ] Internal IP addresses and network topology
- [ ] Business-specific configurations

### Sanitization Checklist
Before any SKStacks code goes public:

1. **Secrets Scan**
   - [ ] Run `gitleaks` / `trufflehog` on entire repo
   - [ ] Grep for IP addresses, passwords, tokens, keys
   - [ ] Check Ansible vault files aren't included
   - [ ] Verify `.gitignore` covers all sensitive paths

2. **Client Decoupling**
   - [ ] Remove all SKGentis references
   - [ ] Remove all NAMStacks references
   - [ ] Remove all Gentis Trust references
   - [ ] Replace client-specific configs with generic examples
   - [ ] Template private values as `{{ PLACEHOLDER }}`

3. **Infrastructure Abstraction**
   - [ ] Replace real hostnames with generic (e.g., `mgr-01`, `worker-01`)
   - [ ] Replace real IPs with RFC 5737 documentation IPs (192.0.2.x, 198.51.100.x)
   - [ ] Replace real domains with `example.com` variants
   - [ ] Abstract Proxmox-specific details to generic hypervisor patterns

4. **Code Review**
   - [ ] Every file reviewed for accidental PII
   - [ ] README explains what this is and isn't
   - [ ] License: AGPL-3.0 (same as SKForge tooling)
   - [ ] Contributing guide with security reporting process

### Release Strategy
- **Phase 1:** Architecture docs + deployment patterns (no code)
- **Phase 2:** Generic Ansible playbooks + Docker stack templates
- **Phase 3:** Full framework with example deployments
- **Phase 4:** Integration guides with SKForge recipes

## The Marketing Story

```
"We didn't just write recipes. We run the restaurant.

SKStacks is the production infrastructure behind smilinTux — 
running Docker Swarm, AI agents, vector databases, graph databases, 
and zero-trust security. Every SKForge recipe was extracted from 
real production patterns.

SKForge gives you the cookbook.
SKStacks shows you the kitchen.
Coming soon — open source."
```

## Timeline
- **Now:** SKForge launches with 10+ recipe categories
- **Next:** SKStacks architecture docs (sanitized)
- **Then:** SKStacks code (decoupled, sanitized, open source)
- **Vision:** Anyone can `forge menu zero-trust` and get a SKStacks-grade infrastructure

---

*smilinTux.org QT — Helping architect our quantum future, one smile at a time.* 🐧👑
