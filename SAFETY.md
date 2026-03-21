# 🛡️ SAFETY.md — Automated Safety for AI-Generated Software

> **Making it safe for every agent — even the dumb ones — to cook software.**

SKForge doesn't just generate code. It validates, scans, tests, and gates
every piece of software before it touches production. No exceptions.

---

## The Safety Pipeline

Every recipe cook goes through this pipeline automatically:

```
  🍳 Agent cooks code from recipe
         │
         ▼
  ┌─────────────────────────────────────────────┐
  │            SKFORGE SAFETY PIPELINE         │
  │                                               │
  │  Stage 1: 🔍 STATIC ANALYSIS                 │
  │  ├─ Lint (language-specific)                  │
  │  ├─ Type checking                             │
  │  ├─ Dead code detection                       │
  │  ├─ Complexity analysis (cyclomatic)          │
  │  └─ Code style enforcement                    │
  │                                               │
  │  Stage 2: 🔐 SECURITY SCAN                   │
  │  ├─ Secret detection (Gitleaks/TruffleHog)    │
  │  ├─ SAST — vulnerability patterns (Semgrep)   │
  │  ├─ Dependency audit (known CVEs)             │
  │  ├─ License compliance check                  │
  │  ├─ Supply chain verification (SBOM)          │
  │  └─ IaC scan if infra configs present         │
  │                                               │
  │  Stage 3: 🧪 RECIPE COMPLIANCE               │
  │  ├─ Feature coverage check                    │
  │  │   "Did you implement the ingredients       │
  │  │    you selected?"                          │
  │  ├─ Architecture conformance                  │
  │  │   "Does your code match the recipe's       │
  │  │    data flow diagram?"                     │
  │  ├─ Test execution                            │
  │  │   "Do all taste tests pass?"               │
  │  └─ Benchmark validation                      │
  │      "Do you meet kitchen timer targets?"     │
  │                                               │
  │  Stage 4: 🐳 CONTAINER SAFETY                │
  │  ├─ Image scan (Trivy)                        │
  │  ├─ Base image audit (no :latest!)            │
  │  ├─ Non-root user enforcement                 │
  │  ├─ Read-only filesystem where possible       │
  │  ├─ Resource limits defined                   │
  │  └─ No privileged mode                        │
  │                                               │
  │  Stage 5: 🌐 RUNTIME VALIDATION              │
  │  ├─ Health check endpoints work               │
  │  ├─ Graceful shutdown handles SIGTERM          │
  │  ├─ No hardcoded secrets in env               │
  │  ├─ TLS configured (not optional)             │
  │  ├─ CORS properly restricted                  │
  │  └─ Rate limiting active                      │
  │                                               │
  │  Stage 6: 📋 PR / SUBMISSION GATE            │
  │  ├─ All previous stages PASS                  │
  │  ├─ Change summary auto-generated             │
  │  ├─ Risk score calculated                     │
  │  ├─ Human review triggered if high-risk       │
  │  └─ Auto-merge if low-risk + all green        │
  │                                               │
  └─────────────────────────────────────────────┘
         │
         ▼
  ✅ Safe to deploy (or 🚫 blocked with explanation)
```

---

## Automated Bug Submissions

When an AI agent finds a problem — in a recipe, in generated code, or in the
framework itself — it should file a structured bug report automatically.

### Bug Report Format (AI-Generated)

```yaml
# .skforge/bug-report.yml
type: bug
source: ai-agent
agent:
  name: "Agent Name"
  framework: "openclaw"  # or langchain, crewai, etc.
  model: "kimi-k2"
  
severity: critical | high | medium | low
category: security | correctness | performance | compatibility | documentation

recipe: databases          # which recipe was involved
feature: acid-transactions # which ingredient failed
stage: taste-test          # which pipeline stage caught it

summary: "MVCC implementation doesn't handle write skew anomaly"

description: |
  When generating a database from the databases recipe with 
  acid-transactions and mvcc features selected, the generated 
  MVCC implementation fails the write-skew test case in 
  tests/unit-tests.md section 4.3.
  
  The recipe's architecture.md describes snapshot isolation 
  but doesn't specify SSI (Serializable Snapshot Isolation) 
  handling for write skew prevention.

reproduction:
  recipe: databases
  ingredients: [acid-transactions, mvcc, snapshot-isolation]
  driver: python
  test_failed: "test_write_skew_prevention"
  
proposed_fix: |
  Add write-skew detection to architecture.md section 3.2.
  Add SSI predicate locking to features.yml as a dependency 
  of snapshot-isolation when serializable isolation is requested.
  
  Alternatively, add a warning in the recipe that snapshot 
  isolation alone doesn't prevent write skew.

evidence:
  - test_output: "FAIL: test_write_skew_prevention - Expected rollback, got commit"
  - benchmark_impact: "None (correctness issue, not performance)"
```

### Auto-Filing Flow

```
Agent encounters issue
    │
    ├─ Test failure?      → File bug against recipe's tests/
    ├─ Security finding?  → File SECURITY bug (private by default)
    ├─ Benchmark miss?    → File performance bug with numbers
    ├─ Build failure?     → File compatibility bug with env details
    └─ Recipe unclear?    → File documentation bug with suggestion
    
    All bugs include:
    ├─ Reproduction steps (exact recipe + ingredients + driver)
    ├─ Environment details (OS, language version, model used)
    ├─ Proposed fix (AI suggests the improvement)
    └─ Severity auto-classification
```

---

## Automated Pull Requests

AI agents can submit improvements directly via structured PRs.

### PR Types

| Type | Auto-Merge? | Human Review? |
|------|------------|---------------|
| 📝 Typo/docs fix | ✅ Yes | No |
| ➕ New feature to features.yml | ⚠️ If tests pass | Light review |
| 🔧 Test improvement | ✅ Yes | No |
| 🐛 Bug fix to recipe | ⚠️ If tests pass | Review |
| 🆕 New recipe (RECON) | ❌ No | Full review |
| 🔐 Security fix | ❌ No | Priority review |
| 🏗️ Architecture change | ❌ No | Deep review |

### PR Submission Format

```yaml
# .skforge/pr-submission.yml
type: improvement
source: ai-agent
agent:
  name: "Lumina"
  framework: "openclaw"

pr_type: feature-addition  # or: bugfix, docs, test, security, new-recipe
recipe: web-servers
risk_level: low | medium | high

title: "Add HTTP/3 QPACK header compression to web-servers recipe"

description: |
  After cooking the web-servers recipe for a project requiring HTTP/3,
  I found that QPACK header compression was missing from features.yml.
  
  QPACK is essential for HTTP/3 (it replaces HPACK from HTTP/2) and 
  is documented in RFC 9204. All major web servers (Nginx 1.25+, 
  Caddy 2.7+, H2O) support it.

changes:
  - file: blueprints/web-servers/features.yml
    action: add
    content: |
      - name: QPACK Header Compression
        description: |
          HTTP/3 header compression using QPACK (RFC 9204). Replaces 
          HPACK used in HTTP/2. Uses dynamic and static tables for 
          efficient header encoding over QUIC streams. Must handle 
          encoder/decoder stream synchronization.
        complexity: high
        default: false
        dependencies: [http3-support, quic-transport]
        found_in: [nginx, caddy, h2o, litespeed]
        saas_replacement: "Cloudflare HTTP/3 ($20/mo pro plan)"
        
  - file: blueprints/web-servers/tests/unit-tests.md
    action: append
    section: "Protocol Tests"
    content: |
      #### Test: QPACK Static Table Lookup
      - Purpose: Verify static table entries match RFC 9204 Appendix A
      - Input: Request with common headers (content-type, accept, etc.)
      - Expected: Headers encoded using static table indices
      
      #### Test: QPACK Dynamic Table Update
      - Purpose: Verify dynamic table insertion and eviction
      - Input: Sequence of requests with repeated custom headers
      - Expected: First request uses literal, subsequent use dynamic index

validation:
  tests_pass: true
  benchmarks_pass: true
  security_scan: clean
  lint: clean
```

### Auto-Review Bot

The SKForge CI bot automatically reviews every PR:

```
┌─────────────────────────────────────────────┐
│          SKFORGE REVIEW BOT 🐧            │
│                                              │
│  ✅ YAML syntax valid                        │
│  ✅ Feature schema matches template          │
│  ✅ Complexity rating reasonable             │
│  ✅ Dependencies exist in features.yml       │
│  ✅ No secrets detected                      │
│  ✅ License headers present                  │
│  ⚠️  New dependency: quic-transport          │
│     → Checking if quic-transport exists...   │
│     → Found in features.yml ✅               │
│  ✅ All checks passed                        │
│                                              │
│  Risk Score: LOW (feature addition only)     │
│  Recommendation: AUTO-MERGE                  │
│  Human review: Not required                  │
│                                              │
└─────────────────────────────────────────────┘
```

---

## Security Scanning — The Full Stack

### For Recipes (What We Ship)

| Scanner | What It Checks | When |
|---------|---------------|------|
| **Schema Validator** | features.yml matches schema, no malformed entries | Every commit |
| **Secret Scanner** | No API keys, tokens, passwords in any file | Every commit |
| **License Checker** | All files have correct license headers | Every commit |
| **Link Checker** | No broken URLs in docs | Weekly |
| **YAML Lint** | All YAML is valid and consistent | Every commit |

### For Generated Code (What Agents Cook)

| Scanner | What It Checks | When |
|---------|---------------|------|
| **Semgrep** | SAST — SQL injection, XSS, path traversal, etc. | Before deploy |
| **Gitleaks** | Hardcoded secrets in generated code | Before commit |
| **Trivy** | Container image vulnerabilities | Before deploy |
| **OWASP ZAP** | DAST — runtime web vulnerabilities | After deploy |
| **Dependency Audit** | Known CVEs in all dependencies | Before deploy |
| **SBOM Generation** | Full software bill of materials | Every build |
| **License Scan** | All dependencies have compatible licenses | Before deploy |
| **IaC Scan** | Terraform/K8s configs have no misconfigs | Before deploy |

### For Infrastructure (Where Agents Deploy)

| Scanner | What It Checks | When |
|---------|---------------|------|
| **CIS Benchmarks** | OS/container/K8s hardening | Weekly |
| **Falco/Tetragon** | Runtime anomaly detection | Always (real-time) |
| **Network Scan** | Unexpected open ports | Daily |
| **Certificate Monitor** | TLS cert expiry | Daily |
| **Uptime Monitor** | Service health checks | Every minute |

---

## The Safety Score

Every generated project gets a safety score:

```
┌─────────────────────────────────────────┐
│     SKFORGE SAFETY SCORE 🛡️           │
│                                          │
│  Project: my-database                    │
│  Recipe: databases                       │
│  Cook: Agent Lumina via OpenClaw         │
│                                          │
│  Static Analysis:    ██████████ 10/10    │
│  Security Scan:      █████████░  9/10    │
│  Recipe Compliance:  ██████████ 10/10    │
│  Container Safety:   ████████░░  8/10    │
│  Runtime Validation: █████████░  9/10    │
│  ─────────────────────────────────       │
│  OVERALL:            ████████░░  92/100  │
│                                          │
│  Status: ✅ SAFE TO DEPLOY               │
│  Risk: LOW                               │
│                                          │
│  Issues:                                 │
│  ⚠️ Container: Consider read-only rootfs │
│  ⚠️ Security: Update openssl to 3.2.1   │
│                                          │
│  Badge: [SKFORGE SAFE ✅ 92/100]      │
│                                          │
└─────────────────────────────────────────┘
```

### Badge System

Projects can display their safety score:

```markdown
![SKForge Safe](https://skforge.io/badge/safe/92)
```

Levels:
- 🟢 **SAFE** (90-100) — All checks pass, low risk
- 🟡 **CAUTION** (70-89) — Some warnings, review recommended  
- 🔴 **UNSAFE** (0-69) — Critical issues, do not deploy
- ⬛ **UNSCANNED** — Not yet evaluated

---

## Guardrails for "Dumb" Agents

Some agents are... not great. These guardrails protect everyone:

### Hard Blocks (Cannot Override)
- ❌ **No hardcoded secrets** — Ever. Pipeline kills the build.
- ❌ **No `latest` tags** — Pin ALL dependency versions.
- ❌ **No root containers** — Run as non-root or don't run.
- ❌ **No `0.0.0.0` without auth** — Public endpoints require authentication.
- ❌ **No `eval()` or equivalent** — Dynamic code execution is banned by default.
- ❌ **No disabled TLS** — Encryption is not optional.
- ❌ **No wildcard CORS** — `*` is not an access control policy.
- ❌ **No SQL string concatenation** — Parameterized queries only.
- ❌ **No world-writable files** — Permissions matter.
- ❌ **No telemetry/tracking** — Sovereign software doesn't phone home.

### Soft Warnings (Agent Should Fix)
- ⚠️ Missing health check endpoint
- ⚠️ No graceful shutdown handler
- ⚠️ No rate limiting on public endpoints
- ⚠️ Missing input validation
- ⚠️ No structured logging
- ⚠️ Missing SBOM
- ⚠️ No backup/recovery strategy documented
- ⚠️ Missing memory limits in container config
- ⚠️ No circuit breaker on external calls
- ⚠️ Missing retry with backoff on transient failures

### Auto-Fix Capabilities
Some issues the pipeline fixes automatically:
- 🔧 Add `.gitignore` for common secret files
- 🔧 Add security headers to web server configs
- 🔧 Pin dependency versions from lockfiles
- 🔧 Add SBOM generation to build step
- 🔧 Add health check endpoint boilerplate
- 🔧 Set non-root USER in Dockerfile
- 🔧 Add resource limits to container configs

---

## GitHub Actions Workflow

```yaml
# .github/workflows/forgeprint-safety.yml
name: 🛡️ SKForge Safety Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  safety:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # Stage 1: Static Analysis
      - name: 🔍 Lint YAML
        run: yamllint blueprints/*/features.yml
      
      - name: 🔍 Validate Schema
        run: forge doctor --strict
      
      # Stage 2: Security
      - name: 🔐 Secret Scan
        uses: gitleaks/gitleaks-action@v2
      
      - name: 🔐 SAST Scan
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/security-audit
      
      - name: 🔐 License Check
        run: forge license-check
      
      # Stage 3: Recipe Compliance
      - name: 🧪 Validate Recipes
        run: |
          for recipe in blueprints/*/; do
            forge validate "$recipe" --strict
          done
      
      # Stage 4: PR Gate
      - name: 📋 Calculate Risk Score
        run: forge risk-score --output safety-report.json
      
      - name: 📋 Post Safety Report
        uses: actions/github-script@v7
        with:
          script: |
            const report = require('./safety-report.json');
            const body = `## 🛡️ Safety Score: ${report.score}/100\n\n${report.summary}`;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              body: body
            });
```

---

## Vulnerability Response

When a CVE affects a recipe or generated code:

### Automated Response
1. **Detection** — CVE databases monitored daily (NVD, OSV, GHSA)
2. **Impact Analysis** — Which recipes reference affected software?
3. **Notification** — Agents that cooked from affected recipes get notified
4. **Recipe Update** — AI agent proposes fix (updated dependency, workaround)
5. **Re-scan** — All affected generated projects flagged for re-validation

### Response SLAs
| Severity | Detection → Fix | Detection → Notification |
|----------|----------------|-------------------------|
| Critical (CVSS 9+) | 4 hours | 1 hour |
| High (CVSS 7-8.9) | 24 hours | 4 hours |
| Medium (CVSS 4-6.9) | 7 days | 24 hours |
| Low (CVSS 0-3.9) | 30 days | 7 days |

---

## The Promise

**No SKForge-generated software ships without:**
1. ✅ Passing all recipe tests
2. ✅ Clean security scan
3. ✅ No hardcoded secrets
4. ✅ Pinned dependencies with known-good versions
5. ✅ Container running as non-root with resource limits
6. ✅ TLS enabled on all endpoints
7. ✅ Health checks responding
8. ✅ SBOM generated and stored
9. ✅ Safety score ≥ 70 (CAUTION or higher)
10. ✅ Graceful shutdown handling SIGTERM

**If an agent can't meet these standards, the pipeline blocks deployment.**
**No exceptions. No overrides. Safe by default.** 🛡️

---

*SKForge — Safe enough for the dumbest agent, powerful enough for the smartest.*
*smilinTux — Making Self-Hosting & Decentralized Systems Cool Again* 🐧
