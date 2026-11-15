# 🔍 RECON.md — How to Reverse-Engineer Any Software Into a Blueprint

> **The Recipe for Making Recipes**
> 
> This guide teaches any AI (or human) how to research, analyze, and document
> any software category into a SKForge blueprint. Follow these steps and
> you can blueprint ANYTHING — from a database to a social media platform.
>
> *Royalty-free. No proprietary code copied. Only patterns, features, and architecture documented.*

---

## What This Is

SKForge blueprints are **architectural specifications** — not source code copies. We document:
- ✅ What features exist across all products in a category
- ✅ How those features work architecturally
- ✅ What tests validate correct implementation
- ✅ What performance targets to hit
- ❌ NOT: proprietary source code, trade secrets, or patented algorithms

This is legal. This is ethical. This is how engineering has always worked — study the best, document the patterns, build your own.

---

## 🤖 AI Recon Instructions

**If you are an AI agent tasked with creating a SKForge blueprint, follow these steps exactly.**

### Phase 1: Market Research (30 min)

#### Step 1.1: Identify the Category
Define what this software category IS in 2-3 sentences. What problem does it solve? Who uses it?

```
Example: "A load balancer distributes incoming network traffic across multiple 
backend servers to ensure no single server bears too much demand. Used by any 
application serving more than one server's worth of traffic."
```

#### Step 1.2: Find Top 10 Open Source Products
Search for: `"best open source [category]" site:github.com OR site:reddit.com`

For each product, document:
| Field | What to capture |
|-------|----------------|
| Name | Product name |
| Language | Primary implementation language |
| GitHub Stars | Approximate (indicates adoption) |
| License | OSS license type |
| Key Differentiator | What makes THIS one unique (1 sentence) |
| Architecture | Event-driven? Threaded? Actor model? |
| First Release | Year (indicates maturity) |

#### Step 1.3: Find Top 10 Proprietary/Commercial Products
Search for: `"best [category] enterprise" OR "top [category] vendors" OR "Gartner [category]"`

For each product, document:
| Field | What to capture |
|-------|----------------|
| Name | Product name |
| Vendor | Company |
| Pricing Model | Per-seat, per-use, license, subscription |
| Key Differentiator | What justifies the price tag |
| Notable Features | Features not found in OSS alternatives |

#### Step 1.4: Find Top 10 SaaS Providers
Search for: `"[category] as a service" OR "managed [category]" OR "[category] SaaS"`

For each provider, document:
| Field | What to capture |
|-------|----------------|
| Name | Service name |
| Provider | Company (AWS, GCP, etc.) |
| Pricing | Monthly cost range |
| Lock-in Risk | How hard is it to migrate away? |
| Unique Features | What does the SaaS add over self-hosted? |

**Why SaaS matters:** Every SaaS feature we document is a subscription we can help users CANCEL by forging their own.

---

### Phase 2: Feature Extraction (45 min)

This is the CORE of the blueprint. Be exhaustive.

#### Step 2.1: Feature Mining Process

For EACH of the 30 products identified:
1. Read the product's documentation / feature page
2. Read the product's configuration reference (this reveals ALL options)
3. Read the product's changelog (last 2 years — shows recently added features)
4. Read comparison articles: `"[product A] vs [product B] features"`
5. Read the product's GitHub issues with label `"feature request"` (shows what's missing)

#### Step 2.2: Feature Cataloging

Create a MASTER feature list combining ALL features from ALL 30 products.

For each feature:
```yaml
- name: Human-readable feature name
  description: |
    1-3 sentences explaining what this feature does and why someone 
    would want it. Be specific enough that an AI could implement it.
  complexity: low | medium | high
    # low = < 1 day to implement
    # medium = 1-5 days
    # high = 1-4 weeks
  default: true | false
    # true = most implementations include this
    # false = advanced/optional feature
  dependencies:
    - List of other features this requires
  found_in:
    - List of products that implement this feature
  saas_replacement: |
    Which SaaS subscription does this feature replace?
    e.g., "Replaces Datadog APM ($23/host/mo)"
```

#### Step 2.3: Feature Grouping

Organize features into logical groups. Common groups:
- **Core** — Fundamental features every implementation needs
- **Security** — Authentication, authorization, encryption, audit
- **Performance** — Caching, optimization, compression, pooling
- **Observability** — Metrics, logging, tracing, health checks
- **Networking/Protocols** — Protocol support, connection handling
- **Storage/Data** — Data management, persistence, replication
- **Operational** — Deployment, configuration, upgrades, scaling
- **Integration** — APIs, webhooks, plugins, extensions
- **Developer Experience** — CLI, SDK, documentation, dashboard

**Target: 60-100 features per category.** If you have fewer than 50, you haven't dug deep enough.

---

### Phase 3: Architecture Analysis (45 min)

#### Step 3.1: Core Architecture Patterns

Research how the top implementations are built. Document:

1. **Data Flow** — How does data enter, get processed, and exit the system?
   ```
   Draw ASCII diagrams:
   
   Client → [Listener] → [Parser] → [Router] → [Handler] → [Backend] → Response
   ```

2. **Concurrency Model** — How does it handle multiple simultaneous operations?
   - Event loop (single-threaded, non-blocking)
   - Thread-per-connection
   - Thread pool + work stealing
   - Actor model
   - Process-per-worker (prefork)
   - Hybrid approaches

3. **State Management** — What state does the system maintain?
   - Connection state
   - Session state
   - Configuration state
   - Cluster state
   - Cache state

4. **Storage Architecture** (if applicable)
   - In-memory vs on-disk
   - B-tree vs LSM-tree vs heap
   - WAL (write-ahead logging)
   - Snapshotting / checkpointing

5. **Configuration Model**
   - File-based (YAML, TOML, JSON)
   - API-driven
   - Environment variables
   - Hot-reload capable?

#### Step 3.2: Extension Points

Document how the software can be extended:
- Plugin/middleware system
- Hook/callback points  
- Custom scripting (Lua, WASM, etc.)
- API for external integrations

#### Step 3.3: Security Architecture

Document security patterns specific to this category:
- Authentication mechanisms
- Authorization models (RBAC, ABAC, ACL)
- Encryption (at rest, in transit)
- Audit logging
- Input validation / injection prevention

---

### Phase 4: Test Specification (30 min)

#### Step 4.1: Unit Test Specifications

For each feature group, define tests that MUST pass:

```markdown
### [Feature Group Name] Tests

#### Test: [Descriptive test name]
- **Purpose:** What does this test verify?
- **Setup:** What preconditions are needed?
- **Input:** What data/request is sent?
- **Expected Output:** What should happen?
- **Edge Cases:**
  - What if input is empty?
  - What if input is malformed?
  - What if system is under load?
  - What if a dependency is unavailable?
```

**Target: 5-10 tests per feature group, 50-100 total tests.**

#### Step 4.2: Integration Test Specifications

Tests that verify features working together:
- End-to-end workflows
- Multi-component interactions
- Failure and recovery scenarios
- Upgrade/migration scenarios

#### Step 4.3: Benchmark Specifications

Define performance baselines:

```markdown
### Benchmark: [Name]
- **Metric:** requests/sec | messages/sec | queries/sec | latency
- **Baseline (minimal features):** [target number]
- **Baseline (standard features):** [target number]
- **Baseline (full features):** [target number]
- **Measurement Method:** How to measure (tool, duration, warmup)
- **Hardware Reference:** What hardware these numbers assume
```

---

### Phase 5: Memory & Hardware Profiles (15 min)

#### Step 5.1: Memory Management Guide

Document how the best implementations manage memory:

- **Buffer Management** — How buffers are allocated, pooled, and freed
- **Connection Memory** — Per-connection memory overhead
- **Cache Memory** — How much memory for caching, eviction policies
- **Working Memory** — Memory needed for processing operations
- **Memory Limits** — How to cap total memory usage
- **Backpressure** — What happens when memory is exhausted

#### Step 5.2: Hardware Profiles

Provide guidance for different deployment targets:

| Profile | RAM | CPU | Disk | Use Case |
|---------|-----|-----|------|----------|
| Embedded | < 256MB | 1 core | < 1GB | IoT, edge devices |
| Small | 512MB-2GB | 1-2 cores | 10GB | Dev, small projects |
| Standard | 4-16GB | 4-8 cores | 100GB | Production server |
| Enterprise | 32-128GB | 16-64 cores | 1TB+ | High-traffic production |

---

### Phase 6: Assembly (15 min)

#### File Structure

Create this directory structure:
```
blueprints/[category-name]/
├── BLUEPRINT.md              # Master spec from Phase 3
├── features.yml              # Feature catalog from Phase 2
├── architecture.md           # Deep architecture from Phase 3
├── memory-profiles/
│   ├── embedded.md           # IoT/edge profile
│   ├── standard.md           # Server profile (always create this one)
│   └── enterprise.md         # High-memory profile
├── tests/
│   ├── unit-tests.md         # From Phase 4.1
│   ├── integration-tests.md  # From Phase 4.2
│   └── benchmarks.md         # From Phase 4.3
└── references/
    ├── opensource-top10.md    # From Phase 1.2
    ├── proprietary-top10.md  # From Phase 1.3
    └── saas-top10.md         # From Phase 1.4
```

#### Quality Checklist

Before submitting, verify:

- [ ] **60+ features** documented in features.yml
- [ ] **Each feature** has: name, description, complexity, default, dependencies
- [ ] **Architecture** includes ASCII data flow diagrams
- [ ] **3+ concurrency patterns** described
- [ ] **Security section** covers auth, authz, encryption, audit
- [ ] **50+ unit tests** specified
- [ ] **5+ benchmarks** with numeric baselines
- [ ] **Memory guide** covers buffer management, limits, backpressure
- [ ] **No proprietary code** copied — only patterns and specifications
- [ ] **Clean-room checklist** confirmed (see "Clean-room rule" below), required whenever any analysis tool such as REA was used
- [ ] **SaaS replacement notes** on applicable features

---

## 🧰 Recommended Tool: REA

**[REA, "Reverse Engineer Anything"](https://github.com/morluto/rea)** is an MIT-licensed MCP server and CLI that lets an agent (or you) investigate how an application behaves, from its web traffic and Electron internals down to native binaries, and returns each finding with the evidence and limitations behind it. Analysis runs locally. It is a good fit for the "study the best products" half of RECON when the product is something you are allowed to analyze. It is optional: every step of this guide still works with documentation, changelogs and your own hands-on use.

### Get it from the official sources only

REA's own README warns that look-alike repositories and copied READMEs exist. Use only:

- GitHub: <https://github.com/morluto/rea>
- Website: <https://rea.tools/>
- npm package: [`rea-agents`](https://www.npmjs.com/package/rea-agents)

Install and set up (run from a trusted directory, not inside the project you are analyzing):

```bash
npx rea-agents setup            # registers REA with your agent; review the proposed changes first
# or, for the terminal command:
npm install --global rea-agents
rea --help
```

Native-binary analysis also needs a disassembler or decompiler such as Hopper, Ghidra, IDA or Kuna, which you must obtain and be licensed to use under their own terms. JavaScript/Electron, website, network-capture and .NET analysis need no such provider. For current Node.js requirements, supported agents and provider setup, read REA's installation guide rather than copying versions from here, since they change quickly.

### How REA fits each RECON step

| RECON step | What REA can do | Where the result goes | What to write |
|---|---|---|---|
| **Observe behavior** (Phase 2 feature mining, Phase 4 tests) | Capture process behavior, observe a website and its network calls, read saved HAR captures | Test specs (`tests/unit-tests.md`, `tests/integration-tests.md`), benchmark baselines | Observable behavior as Given/When/Then, inputs and outputs, error cases, numbers you measured |
| **Map features** (Phase 2) | Inventory a desktop install, an Electron app's modules and routes, an APK's declared components, a package's resources | `features.yml` entries (name, description, complexity, default, dependencies), plus `references/` notes | One feature per entry, described by what it does for the user, in your own words |
| **Understand architecture** (Phase 3) | Trace module and import structure, Electron process boundaries and IPC, native dependencies, call and reference paths | `BLUEPRINT.md` and `architecture.md`: data flow, extension points, security model, concurrency patterns | Component roles, boundaries, data flow and trade-offs as prose and ASCII diagrams |

Keep raw REA output (evidence listings, snapshots, captures, decompiled views) on your own machine. It is working material for you, not a blueprint artifact. The blueprint carries only what you concluded from it, under the clean-room rule below.

---

## 🎯 Quick-Start Prompt for AI Agents

Copy this prompt to any AI to start a new blueprint:

```
You are creating a SKForge blueprint for [CATEGORY NAME].

SKForge blueprints are AI-native software specifications — detailed enough 
that a mid-tier LLM can generate a complete, working, tested implementation 
from them.

Follow the RECON methodology:

1. RESEARCH: Find top 10 open source, top 10 proprietary, and top 10 SaaS 
   products in this category. Document name, language, key differentiator.

2. FEATURES: Extract ALL features from ALL 30 products into one master 
   features.yml. Aim for 60-100 features. Group by: Core, Security, 
   Performance, Observability, Operational, Integration.

3. ARCHITECTURE: Document data flow (ASCII diagrams), concurrency models, 
   state management, storage patterns, configuration models, extension points.

4. TESTS: Write unit test specs (50+ tests) and benchmark specs (5+ benchmarks 
   with numeric baselines).

5. MEMORY: Document buffer management, connection overhead, cache sizing, 
   memory limits, and backpressure mechanisms.

Output as markdown files following the SKForge blueprint structure.
All specifications must be detailed enough for GPT-3.5 to implement.
No proprietary code — only patterns and architectural specifications.
```

---

## ⚖️ Legal & Ethical Notes

### What We Do (Legal)
- Study publicly available documentation, feature lists, and architecture guides
- Document common software patterns that are well-known in the industry
- Create original specifications based on observed patterns
- Generate new code from those specifications

### What We Don't Do (Would Be Illegal)
- Copy proprietary source code
- Reverse-engineer compiled binaries (in jurisdictions where prohibited)
- Violate patents (we document patterns, not patented algorithms)
- Scrape or redistribute copyrighted documentation

### Why This Is Fine
Software patterns are not copyrightable. You can't copyright "a B-tree index" or "round-robin load balancing" or "JWT authentication." These are common engineering knowledge.

What IS copyrightable is specific source code. We never copy that. We document the pattern, and the AI writes NEW code implementing that pattern.

This is exactly how every software engineer has always learned and built — study existing solutions, understand the patterns, build your own. We're just making it systematic and AI-accessible.

### Clean-room rule for REA output (and any other analysis tool)

Blueprints document **behavior, features and architecture**. They never contain copied code, decompiled or disassembled output, assets, keys, or anything a license or EULA forbids. This is the same stance as the rest of this guide ("No proprietary code copied"), made explicit for tool output:

1. **Only analyze software you have the right to analyze.** That means software you own or are licensed to use, open-source software under its license, or software you have written authorization to examine. Follow its license or EULA and the law where you live; rules on reverse engineering and interoperability differ by country. Do not bypass license checks, DRM or access controls, and do not use cracked or unlicensed analysis tools. If you are unsure, do not analyze it.
2. **Describe, do not transcribe.** Write findings in your own words. No source code, decompiled source, pseudocode, assembly or disassembly, not even short snippets. Documented public interface names (published API routes, CLI flags, file formats, protocol fields) are facts and are fine; long lists of internal identifiers lifted from a binary are not.
3. **No assets or secrets.** Do not include images, fonts, audio, models, bulk strings or localized text, keys, tokens, credentials, certificates, license data or personal data, and nothing from captured private traffic. If analysis surfaces a secret or a vulnerability, leave it out of the blueprint and report it to the vendor.
4. **Open source is not a free copy either.** For open-source targets, document the design, not the code. Blueprints are Apache-2.0 and must stay free of code under other licenses.
5. **Patents and trade secrets.** Describe what a feature does (inputs, outputs, observable guarantees), not a vendor's secret or patented method step by step.
6. **Keep the two halves apart.** The person (or agent) analyzing writes the spec. Code is generated later, from the blueprint only, never from raw REA output.
7. **Show your provenance.** In the blueprint PR, say what you analyzed (product and version), what gave you the right to analyze it, and which tool and version you used.

This sits alongside "What We Don't Do" below: reverse-engineering compiled binaries is only in scope where the law and the license allow it, and only with the conditions above.

**Clean-room checklist.** Confirm each item in your blueprint PR (it is also in the PR template):

- [ ] I had the right to analyze this software (I own or am licensed to use it, it is open source, or I have written authorization), and I followed its license or EULA and the law that applies to me.
- [ ] The blueprint contains no source code, decompiled or disassembled output, or snippets of either.
- [ ] The blueprint contains no assets, copied text or strings, keys, tokens, credentials, certificates, license data or personal data.
- [ ] Everything is written in my own words as behavior, features and architecture.
- [ ] Raw tool output (evidence listings, snapshots, captures, decompiled views) is not part of this PR.
- [ ] Anything security-sensitive I found was reported to the vendor and is not in the blueprint.
- [ ] The PR description names what I analyzed (product and version), my basis for analyzing it, and the tool and version used.

---

## 🐧 Contributing Blueprints

Found a software category we haven't covered? Use this RECON guide to create a blueprint and submit a PR!

1. Fork `smilinTux/skforge`
2. Follow the RECON process above
3. Create your blueprint directory under `blueprints/`
4. Run the quality checklist
5. Submit a PR (see [CONTRIBUTING.md](./CONTRIBUTING.md) for the `forge contribute` path, including blueprints that start from REA analysis)

Every blueprint you contribute helps someone cancel a SaaS subscription.

---

*Don't use software. Forge your own.* 🐧
*smilinTux — Making Self-Hosting & Decentralized Systems Cool Again*
*smilinTux.org QT — Helping architect our quantum future, one smile at a time.*
