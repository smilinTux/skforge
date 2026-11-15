## What does this change?

<!-- A sentence or two. -->

## Blueprint PRs: clean-room checklist

Required for any blueprint or feature list that came from analyzing software, whether with REA, another tool, or by hand. Tick each item, or delete this section if the PR is not a blueprint. Details: [RECON.md](../RECON.md#clean-room-rule-for-rea-output-and-any-other-analysis-tool).

- [ ] I had the right to analyze this software (I own or am licensed to use it, it is open source, or I have written authorization), and I followed its license or EULA and the law that applies to me.
- [ ] The blueprint contains no source code, decompiled or disassembled output, or snippets of either.
- [ ] The blueprint contains no assets, copied text or strings, keys, tokens, credentials, certificates, license data or personal data.
- [ ] Everything is written in my own words as behavior, features and architecture.
- [ ] Raw tool output (evidence listings, snapshots, captures, decompiled views) is not part of this PR.
- [ ] Anything security-sensitive I found was reported to the vendor and is not in the blueprint.
- [ ] Below, I name what I analyzed (product and version), my basis for analyzing it, and the tool and version used.

**Analyzed:** <!-- product and version -->
**Basis:** <!-- own license / open source / written authorization -->
**Tool:** <!-- for example REA x.y.z, or "documentation and hands-on use only" -->
