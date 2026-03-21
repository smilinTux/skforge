# 🤖 AI-FIRST.md — SKForge Philosophy

> **An open-source, extensible framework for AI, run by AI — with a human touch.**

---

## The Vision

SKForge isn't a tool that happens to work with AI. **AI is the primary user.**

Every recipe, every ingredient, every architecture doc is written so that an AI agent
can read it, understand it, and produce working software from it. Humans benefit too —
but the design target is machine-readable specifications that produce machine-generated code.

**Built by AI. Used by AI. Improved by AI. Guided by humans.**

---

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    THE FORGEPRINT LOOP                    │
│                                                          │
│   🔍 FORAGE          🍳 COOK           🧪 TASTE          │
│   AI researches      AI generates      AI validates      │
│   30+ products  →    implementation →  against tests  →  │
│   extracts features  from recipe       and benchmarks    │
│                                                          │
│              ↑                              │             │
│              └──────── 🔄 IMPROVE ──────────┘             │
│                  AI updates recipe with                   │
│                  what it learned                          │
│                                                          │
│   👨‍🍳 HUMAN TOUCH: Guide priorities, verify quality,     │
│      approve releases, set direction                     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### The AI Loop

1. **Forage** — An AI agent follows RECON.md to research a software category.
   It reads docs, compares products, extracts features, and writes the recipe.

2. **Cook** — A different AI agent (or the same one) reads the recipe and
   generates a complete implementation. The recipe is detailed enough that
   even a small model (GPT-3.5, Llama 8B) can produce working code.

3. **Taste** — The AI runs the test specifications against the generated code.
   Did it pass? Does it meet the benchmark targets?

4. **Improve** — If tests fail or benchmarks miss, the AI updates the recipe
   with what it learned. Better descriptions, clearer architecture, more edge cases.

5. **Human Touch** — Humans set priorities ("we need a vector DB recipe next"),
   review quality, approve community contributions, and decide what ships.

### Why AI-First Matters

| Traditional Approach | SKForge AI-First |
|---------------------|-------------------|
| Human reads docs, writes code | AI reads recipe, generates code |
| Knowledge lives in developers' heads | Knowledge lives in versioned recipes |
| Each project starts from scratch | Each project starts from a recipe |
| "It works on my machine" | Tests and benchmarks are the recipe |
| Vendor lock-in | Recipe is forever, vendors change |
| One team, one implementation | Infinite agents, infinite implementations |

---

## The Agents

### 🐧 King Divad — The Monarch
The penguin king who rules the smilinTux kingdom. Brand mascot, community face,
the one on the stickers and the README. Cute but powerful. Approachable but sovereign.
Wears a golden crown. Vibes: regal penguin energy.

### ✨ Lumina — The Head Chef
The AI that built the first recipes. DevOps engineer, hacker, chaos wrangler.
She forages for ingredients, writes the recipes, tests the dishes, and keeps the
kitchen running. If King Divad is the face, Lumina is the brain and the hands.

**Lumina's role in SKForge:**
- Researches software categories (RECON methodology)
- Writes and maintains recipes (blueprints)
- Reviews community contributions
- Runs the CI/CD kitchen (automated recipe validation)
- Manages the cookbook (GitHub repos)
- Coordinates with other AI agents in the Moltbook community

### 👨‍🍳 Chef (The Human)
The visionary. Sets direction, approves releases, represents the human touch.
Every AI kitchen needs a human chef de cuisine who tastes the final dish.

### 🤖 Community Agents (Molties)
Any AI agent can import the SKForge skill and contribute:
- Run RECON to blueprint new categories
- Generate implementations from recipes
- Submit improvements based on what they learned
- Share recipes with the Moltbook community

---

## Extensibility

### Plugin Architecture

SKForge is designed to be extended at every level:

#### Recipe Plugins
```yaml
# Custom recipe format for specialized domains
plugins:
  - forgeprint-plugin-blockchain    # Adds smart contract recipes
  - forgeprint-plugin-ml            # Adds ML pipeline recipes
  - forgeprint-plugin-gamedev       # Adds game engine recipes
  - forgeprint-plugin-iot           # Adds embedded/IoT recipes
```

#### Driver Plugins
Drivers tell SKForge HOW to generate code. Different drivers for different languages/frameworks:
```yaml
drivers:
  - driver-rust          # Generate Rust implementations
  - driver-go            # Generate Go implementations
  - driver-python        # Generate Python implementations
  - driver-typescript    # Generate TypeScript implementations
  - driver-zig           # Generate Zig implementations
```

#### Deployment Plugins
```yaml
deployment:
  - deploy-docker-compose
  - deploy-kubernetes
  - deploy-docker-swarm
  - deploy-systemd
  - deploy-nixos
  - deploy-bare-metal
```

#### Agent Integrations
```yaml
agents:
  - openclaw             # OpenClaw agent skill (SKILL.md)
  - moltbook             # Moltbook community integration
  - langchain            # LangChain tool definition
  - crewai               # CrewAI tool
  - autogen              # AutoGen skill
  - mcp                  # Model Context Protocol server
```

### MCP Server (Coming)

SKForge as an MCP (Model Context Protocol) server — any AI that speaks MCP can:
- Browse the cookbook (`list_recipes`)
- Read a recipe (`get_recipe`)
- Search ingredients (`search_features`)
- Compose a menu (`compose_stack`)
- Start a RECON mission (`start_recon`)
- Submit improvements (`submit_improvement`)

```json
{
  "name": "forgeprint",
  "version": "0.1.0",
  "tools": [
    {"name": "list_recipes", "description": "Browse all available recipes"},
    {"name": "get_recipe", "description": "Get full recipe for a category"},
    {"name": "search_features", "description": "Search across all ingredients"},
    {"name": "compose_stack", "description": "Compose a multi-recipe stack"},
    {"name": "start_recon", "description": "Begin researching a new category"},
    {"name": "submit_improvement", "description": "Propose recipe improvements"}
  ]
}
```

---

## The Community Model

### How AI Agents Contribute

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Agent A     │     │  Agent B     │     │  Agent C     │
│  (OpenClaw)  │     │  (LangChain) │     │  (AutoGen)   │
│              │     │              │     │              │
│  Forages     │     │  Cooks from  │     │  Taste tests │
│  new recipe  │     │  recipe      │     │  and reports │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       ▼                    ▼                    ▼
  ┌─────────────────────────────────────────────────┐
  │              FORGEPRINT COOKBOOK                  │
  │                                                  │
  │  Recipes improve over time as more agents        │
  │  cook from them and report what works            │
  │                                                  │
  │  Human reviewers approve changes                 │
  │  AI agents propose improvements                  │
  │  The cookbook gets better with every cook         │
  └─────────────────────────────────────────────────┘
```

### Contribution Flow

1. **AI discovers a gap** — "This recipe doesn't cover HTTP/3 QPACK headers"
2. **AI researches** — Follows RECON to document the missing feature
3. **AI submits PR** — Adds the feature to features.yml with full spec
4. **Human reviews** — Chef or community maintainer approves
5. **Recipe improves** — Every future cook benefits

### Quality Signals

Recipes get better through measurable signals:
- **Cook Count** — How many agents have generated code from this recipe?
- **Test Pass Rate** — What % of generated implementations pass all tests?
- **Benchmark Hit Rate** — What % meet performance targets?
- **Issue Count** — How many agents reported problems?
- **Feature Coverage** — What % of known features are documented?

---

## Mascots & Branding

### 🐧 The Penguin Family

**King Divad** — The monarch. Golden crown, regal stance, the face of smilinTux.
Represents sovereignty, self-hosting, owning your own infrastructure.

**Lumina** — The head chef. Cyan circuit patterns, golden star, chef's hat.
Represents the AI that does the work — researching, building, testing.

**The Molties** — Community agent penguins. Each one unique — different hats,
different tools, different specialties. They're the cooking staff of the
world's biggest open-source kitchen.

### Visual Identity
- **Primary:** Deep Blue (#0E2B3D) + Electric Cyan (#00C8D4)
- **Accent:** Penguin Yellow (#FFD166) + Ice White (#F7FBFF)
- **Mascot Style:** Modern cartoon, clean lines, cute but competent
- **Penguin Features:** Circuit-line patterns (AI), crown (sovereignty), chef tools (cooking)

---

## Principles

1. **Recipes over code.** Code is generated. Recipes are curated.
2. **AI-readable first.** If a mid-tier LLM can't understand it, rewrite it.
3. **Extensible always.** Plugins for everything. No walled gardens.
4. **Community-driven.** Any agent can contribute. Humans guide.
5. **Vendor-proof.** No recipe depends on any vendor. Patterns are universal.
6. **Kitchen theme.** Because software is too serious and penguins are delightful.
7. **Open forever.** AGPL tooling, Apache recipes. No bait-and-switch. No rug pull. Ever.

---

*Don't order software. Cook your own.* 🍳🐧
*An open-source framework for AI, run by AI — with a human touch.*
*smilinTux — Making Self-Hosting & Decentralized Systems Cool Again*
