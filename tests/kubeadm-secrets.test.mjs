import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname } from 'node:path';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import { runKeyring, validateKeyring } from '../packages/kubeadm-secrets/keyring.mjs';

const file = 'profiles/kubernetes/indigo-encryption-keyring.age';
const syntheticKey = Buffer.alloc(32, 42).toString('base64');
const recovery = { version: 1, cluster: 'indigo', keys: [{ name: 'indigo-v1', secret: syntheticKey }] };
const cipher = '-----BEGIN AGE ENCRYPTED FILE-----\nsynthetic-ciphertext\n';

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'kubeadm-secrets-test-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(join(root, 'profiles/kubernetes'), { recursive: true });
  writeFileSync(join(root, 'secrets.nix'), '{}');
  writeFileSync(join(root, 'profiles/kubernetes/encryption-recipients.nix'), '{}');
  const calls = [];
  const logs = [];
  const options = { root, registry: { indigo: { file, publicKeys: ['admin', 'control-01', 'control-02', 'control-03'] } }, age: '/age', args: ['init', 'indigo'] };
  const deps = {
    random: size => { assert.equal(size, 32); return Buffer.alloc(size, 42); },
    log: message => logs.push(message),
    run: (command, args, options) => {
      calls.push({ command, args, options });
      return { status: 0, stdout: command === '/age' ? cipher : '' };
    },
  };
  return { root, options, deps, calls, logs };
}

test('init encrypts for all selected recipients, writes only ciphertext, and copies recovery locally', t => {
  const f = fixture(t);
  runKeyring(f.options, f.deps);
  assert.equal(readFileSync(join(f.root, file), 'utf8'), cipher);
  assert.equal(statSync(join(f.root, file)).mode & 0o777, 0o600);
  assert.deepEqual(f.calls[0].args, ['--encrypt', '--armor', '--recipient', 'admin', '--recipient', 'control-01', '--recipient', 'control-02', '--recipient', 'control-03']);
  assert.deepEqual(JSON.parse(f.calls[0].options.input), recovery);
  assert.equal(f.calls[1].command, '/usr/bin/pbcopy');
  assert.equal(f.calls[1].options.input, f.calls[0].options.input);
  assert.ok(!f.logs.join('\n').includes(syntheticKey));
  assert.ok(!JSON.stringify(f.calls.map(c => c.args)).includes(syntheticKey));
});

test('init never replaces an existing file or clipboard', t => {
  const f = fixture(t);
  writeFileSync(join(f.root, file), 'existing');
  assert.throws(() => runKeyring(f.options, f.deps), /refusing to replace/);
  assert.equal(readFileSync(join(f.root, file), 'utf8'), 'existing');
  assert.equal(f.calls.length, 0);
});

test('encryption failure neither creates a file nor forwards subprocess diagnostics', t => {
  const f = fixture(t);
  f.deps.run = () => ({ status: 1, stdout: syntheticKey, stderr: syntheticKey });
  assert.throws(() => runKeyring(f.options, f.deps), /^Error: Encryption failed; no keyring file was created\.$/);
  assert.ok(!existsSync(join(f.root, file)));
  assert.equal(f.logs.length, 0);
});

test('clipboard failure retains recoverable ciphertext and refuses regeneration', t => {
  const f = fixture(t);
  f.deps.run = command => ({ status: command === '/age' ? 0 : 1, stdout: cipher });
  assert.throws(() => runKeyring(f.options, f.deps), /encrypted file is retained/);
  assert.equal(readFileSync(join(f.root, file), 'utf8'), cipher);
  assert.throws(() => runKeyring(f.options, f.deps), /refusing to replace/);
});

test('copy-recovery decrypts the existing key without creating a replacement', t => {
  const f = fixture(t);
  writeFileSync(join(f.root, file), cipher);
  f.options.args = ['copy-recovery', 'indigo', '/private/admin-identity'];
  f.deps.random = () => { throw new Error('must not generate a new key'); };
  f.deps.run = (command, args, options) => {
    f.calls.push({ command, args, options });
    return { status: 0, stdout: command === '/age' ? JSON.stringify(recovery) : '' };
  };
  runKeyring(f.options, f.deps);
  assert.deepEqual(f.calls[0].args, ['--decrypt', '--identity', '/private/admin-identity', join(f.root, file)]);
  assert.deepEqual(JSON.parse(f.calls[1].options.input), recovery);
  assert.equal(readFileSync(join(f.root, file), 'utf8'), cipher);
  assert.ok(!f.logs.join('\n').includes(syntheticKey));
});

test('recovery parse failures never echo the secret', t => {
  const f = fixture(t);
  f.options.args = ['copy-recovery', 'indigo', '/private/admin-identity'];
  f.deps.run = () => ({ status: 0, stdout: `invalid-${syntheticKey}` });
  assert.throws(() => runKeyring(f.options, f.deps), /^Error: Invalid recovery record; clipboard was not changed\.$/);
});

test('keyring validation rejects wrong clusters, malformed keys and duplicate names', () => {
  assert.deepEqual(validateKeyring(recovery, 'indigo'), recovery);
  assert.throws(() => validateKeyring(recovery, 'other'), /metadata/);
  for (const secret of ['', Buffer.alloc(31).toString('base64'), syntheticKey + '\n']) {
    assert.throws(() => validateKeyring({ ...recovery, keys: [{ name: 'key1', secret }] }, 'indigo'), /32 random bytes/);
  }
  assert.throws(() => validateKeyring({ ...recovery, keys: [recovery.keys[0], recovery.keys[0]] }, 'indigo'), /duplicate/);
});

test('recipient policy is shared with agenix and limited to admins plus the three controls', () => {
  const registry = readFileSync(new URL('../profiles/kubernetes/encryption-recipients.nix', import.meta.url), 'utf8');
  assert.match(registry, /keys\.groups\.admins/);
  assert.deepEqual([...registry.matchAll(/keys\.hosts\.([a-z0-9-]+)/g)].map(m => m[1]), [
    'srv-lx-k8s-indigo-control-01', 'srv-lx-k8s-indigo-control-02', 'srv-lx-k8s-indigo-control-03',
  ]);
  assert.ok(!registry.includes('allHosts'));
  for (const source of ['../secrets.nix', '../packages/kubeadm-secrets/default.nix']) {
    assert.match(readFileSync(new URL(source, import.meta.url), 'utf8'), /import .*encryption-recipients\.nix/);
  }
});

test('real age ciphertext can be decrypted by the selected recovery recipient', { skip: !process.env.AGE_TEST_BIN }, t => {
  const f = fixture(t);
  const age = resolve(process.env.AGE_TEST_BIN);
  const identity = join(f.root, 'test-identity');
  const generated = spawnSync(join(dirname(age), 'age-keygen'), ['-o', identity], { encoding: 'utf8' });
  assert.equal(generated.status, 0, 'test identity generation failed');
  const publicKey = spawnSync(join(dirname(age), 'age-keygen'), ['-y', identity], { encoding: 'utf8' });
  assert.equal(publicKey.status, 0);
  f.options.age = age;
  f.options.registry.indigo.publicKeys = [publicKey.stdout.trim()];
  f.deps.run = (command, args, options) => command === '/usr/bin/pbcopy' ? { status: 0 } : spawnSync(command, args, options);
  runKeyring(f.options, f.deps);
  const decrypted = spawnSync(age, ['-d', '-i', identity, join(f.root, file)], { encoding: 'utf8' });
  assert.equal(decrypted.status, 0);
  assert.deepEqual(JSON.parse(decrypted.stdout), recovery);
  assert.ok(!readFileSync(join(f.root, file), 'utf8').includes(syntheticKey));
});
