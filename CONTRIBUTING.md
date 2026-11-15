# Contributing to SKForge 🔧

First off — **thank you**. You're helping build something that makes software free for everyone.

## Ways to Contribute

### 🆕 Add a New Blueprint Category

1. Fork the repo
2. Create a new directory under `blueprints/your-category/`
3. Follow the [Blueprint Template](./blueprints/TEMPLATE/)
4. Research top 10 OSS + proprietary products in the category
5. Build an exhaustive feature list (aim for 50-100 features)
6. Write architecture patterns, test specs, and memory profiles
7. Submit a PR

### 🔬 From REA analysis to blueprint

[REA](https://github.com/morluto/rea) ("Reverse Engineer Anything") is our recommended tool for studying how an application really behaves. If you use it (or any similar tool) to learn something worth sharing, turn it into a blueprint that everyone can build from:

1. **Check you may analyze it.** Only software you own or are licensed to use, open-source software, or software you are authorized to examine. Read the clean-room rule in [RECON.md](./RECON.md#clean-room-rule-for-rea-output-and-any-other-analysis-tool).
2. **Get REA from the official sources only:** [github.com/morluto/rea](https://github.com/morluto/rea), [rea.tools](https://rea.tools/) or the [`rea-agents`](https://www.npmjs.com/package/rea-agents) npm package. Setup steps are in the REA section of [RECON.md](./RECON.md).
3. **Analyze locally and keep the raw output to yourself.** Evidence listings, snapshots, captures and decompiled views stay on your machine.
4. **Write the blueprint from your own notes, in your own words:** behavior, features and architecture, never code, assets or keys. Features go in `features.yml`, the design in `BLUEPRINT.md` and `architecture.md`, observed behavior in `tests/`.
5. **Scaffold and submit with `forge contribute`:**
   ```bash
   gh repo fork smilinTux/skforge --clone && cd skforge           # forge contribute commits and pushes from the checkout it runs in
   node forge.mjs contribute new <blueprint-name>                 # scaffold from the template and submit
   # or, for a blueprint you already wrote under blueprints/<category>/:
   node forge.mjs contribute <category>
   ```
   It checks that `BLUEPRINT.md` and `features.yml` exist and are filled in, creates a branch, commits and opens the PR with `gh`. If `gh` is missing it prints the manual fork-and-PR steps.
6. **Confirm the clean-room checklist in the PR.** `forge contribute` opens the PR with the checklist already in its description (the same text as the [PR template](./.github/pull_request_template.md)). Edit the description, tick each item you can honestly confirm, and fill in what you analyzed, your basis for analyzing it, and the tool and version. forge cannot verify the items for you.

A reviewer will not merge a blueprint whose PR leaves the checklist unconfirmed.

### ✅ Add Features to Existing Blueprints

Found a feature we missed? Open a PR adding it to the category's `features.yml`. Include:
- Feature name
- Description (1-2 sentences)
- Complexity (low/medium/high)
- Dependencies (other features it requires)
- Which products implement it (reference)

### 🧪 Improve Test Specifications

Better tests = better generated software. Help us by:
- Adding edge case test specs
- Improving benchmark baselines
- Adding integration test scenarios

### 📝 Improve Documentation

- Fix typos, clarify descriptions
- Add architectural diagrams
- Write tutorials or guides
- Translate blueprints

### 🐛 Report Issues

- Missing features in a category
- Incorrect architectural guidance
- Test specs that don't cover important cases
- Suggestions for new categories

## Quality Standards

- **Be clean-room**: behavior, features and architecture only. No copied code, decompiled output, assets, keys or anything a license forbids. See [RECON.md](./RECON.md#clean-room-rule-for-rea-output-and-any-other-analysis-tool)

- **Be exhaustive**: More detail = better AI output
- **Be specific**: Vague specs produce vague code
- **Be tested**: Every feature needs test criteria
- **Be language-agnostic**: Blueprints should work for any target language
- **Be honest**: If a feature is complex, say so

## Code of Conduct

Be excellent to each other. We're building something for everyone — act like it.

## License

By contributing, you agree that your contributions will be licensed under AGPL-3.0 (tooling) or Apache 2.0 (blueprints).

---

**Questions?** Open a Discussion or join our [Discord](https://discord.gg/smilintux).

*smilinTux — a [smilinTux.org QT](https://smilintux.org) open source project* 🐧👑
