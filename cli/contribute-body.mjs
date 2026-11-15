/**
 * PR body that `forge contribute` opens a blueprint PR with.
 *
 * The clean-room checklist lives here (not only in the PR template) so the PR
 * that forge opens already carries it. test/contribute-body.test.mjs keeps this
 * list identical to .github/pull_request_template.md and RECON.md.
 */

export const CLEAN_ROOM_CHECKLIST = [
  'I had the right to analyze this software (I own or am licensed to use it, it is open source, or I have written authorization), and I followed its license or EULA and the law that applies to me.',
  'The blueprint contains no source code, decompiled or disassembled output, or snippets of either.',
  'The blueprint contains no assets, copied text or strings, keys, tokens, credentials, certificates, license data or personal data.',
  'Everything is written in my own words as behavior, features and architecture.',
  'Raw tool output (evidence listings, snapshots, captures, decompiled views) is not part of this PR.',
  'Anything security-sensitive I found was reported to the vendor and is not in the blueprint.',
  'The PR description names what I analyzed (product and version), my basis for analyzing it, and the tool and version used.',
];

/**
 * @param {{category: string, features: number|string}} opts
 * @returns {string} Markdown PR body.
 */
export function buildContributePrBody({ category, features }) {
  const items = CLEAN_ROOM_CHECKLIST.map((item) => `- [ ] ${item}`).join('\n');
  return `New blueprint: **${category}**

Generated via \`forge contribute\`. Features: ${features}

## Clean-room checklist

Edit this description and tick each item before asking for review. forge cannot verify them for you. Details: RECON.md, "Clean-room rule".

${items}

**Analyzed:** <!-- product and version -->
**Basis:** <!-- own license / open source / written authorization -->
**Tool:** <!-- for example REA x.y.z, or "documentation and hands-on use only" -->
`;
}
