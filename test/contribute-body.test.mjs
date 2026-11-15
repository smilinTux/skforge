import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildContributePrBody, CLEAN_ROOM_CHECKLIST } from '../cli/contribute-body.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const read = (p) => readFileSync(join(root, p), 'utf8');

/** Checklist items ("- [ ] text") in a markdown file, in order. */
const unticked = (md) => [...md.matchAll(/^- \[ \] (.+)$/gm)].map((m) => m[1]);

test('PR body names the blueprint and its feature count', () => {
  const body = buildContributePrBody({ category: 'databases', features: 64 });
  assert.match(body, /New blueprint: \*\*databases\*\*/);
  assert.match(body, /Features: 64/);
});

test('PR body carries every clean-room item, unticked', () => {
  const body = buildContributePrBody({ category: 'x', features: '?' });
  assert.equal(CLEAN_ROOM_CHECKLIST.length, 7);
  assert.deepEqual(unticked(body), CLEAN_ROOM_CHECKLIST);
  assert.doesNotMatch(body, /- \[x\]/i, 'forge must not pre-tick items it cannot verify');
});

test('PR body asks for provenance fields', () => {
  const body = buildContributePrBody({ category: 'x', features: 1 });
  for (const field of ['**Analyzed:**', '**Basis:**', '**Tool:**']) {
    assert.ok(body.includes(field), `missing ${field}`);
  }
});

test('checklist is identical in the PR template and RECON.md', () => {
  assert.deepEqual(unticked(read('.github/pull_request_template.md')), CLEAN_ROOM_CHECKLIST);
  // RECON.md also has the unrelated blueprint quality checklist; take the clean-room one.
  const recon = read('RECON.md');
  assert.deepEqual(unticked(recon.slice(recon.indexOf('**Clean-room checklist.**'))), CLEAN_ROOM_CHECKLIST);
});

test('hostile category text stays plain text in the body', () => {
  const body = buildContributePrBody({ category: 'a"b`c$(id)', features: 1 });
  assert.ok(body.includes('a"b`c$(id)'));
});

test('forge contribute opens the PR with --body-file and no shell', () => {
  const src = read('forge.mjs');
  assert.match(src, /buildContributePrBody\(/);
  assert.match(src, /'--body-file'/);
  assert.doesNotMatch(src, /gh pr create --repo \$\{GITHUB_OWNER\}[^`]*--body "/, 'body must not be interpolated into a shell string');
});
