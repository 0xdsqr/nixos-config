import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, readdirSync, statSync, rmSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const source = fileURLToPath(new URL('../modules/nixos/etcd-backup/export.sh', import.meta.url));
const collector = fileURLToPath(new URL('../modules/nixos/etcd-backup/collect.sh', import.meta.url));
const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'etcd-backup-test-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  for (const path of ['bin', 'data', 'backups', 'metrics']) mkdirSync(join(root, path));
  const env = {
    ...process.env,
    PATH: `${join(root, 'bin')}:${process.env.PATH}`,
    ETCD_DATA_DIRECTORY: join(root, 'data'),
    ETCD_BACKUP_LOCK: join(root, 'source.lock'),
    CRICTL_CONFIG: join(root, 'crictl.yaml'),
    AGE_RECIPIENTS_FILE: join(root, 'recipients'),
    ETCD_CLUSTER_NAME: 'indigo',
    BACKUP_MOUNT: root,
    BACKUP_DIRECTORY: join(root, 'backups'),
    BACKUP_SOURCE: '100.102.143.47',
    BACKUP_KNOWN_HOSTS: join(root, 'known-hosts'),
    BACKUP_RETENTION_DAYS: '31',
    BACKUP_METRICS_DIRECTORY: join(root, 'metrics'),
    TEST_CALLS: join(root, 'calls'),
    TEST_MODE: '',
  };
  const mock = String.raw`#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const command = path.basename(process.argv[1]);
const args = process.argv.slice(2);
const mode = process.env.TEST_MODE;
fs.appendFileSync(process.env.TEST_CALLS, JSON.stringify({command, args}) + '\n');
if (command === 'crictl') {
  if (args.includes('ps')) process.stdout.write(mode === 'multiple' ? 'abc\ndef\n' : 'abc123\n');
  else if (args.includes('etcdctl')) {
    if (mode === 'save-failure') process.exit(1);
    fs.writeFileSync(args.at(-1), 'synthetic database');
    console.log('etcdctl informational stdout must not contaminate ciphertext');
  } else if (args.includes('status')) {
    console.log(JSON.stringify({revision: 123, totalKey: mode === 'empty' ? 0 : 40}));
  } else if (args.includes('restore')) {
    if (mode === 'restore-failure') process.exit(1);
    const output = args.find(arg => arg.startsWith('--data-dir=')).slice('--data-dir='.length);
    if (!output.startsWith(process.env.ETCD_DATA_DIRECTORY + '/dsqr-backup.') || !output.endsWith('/restore-check')) process.exit(2);
    fs.mkdirSync(output);
    fs.writeFileSync(path.join(output, 'synthetic-restored-db'), 'synthetic');
  } else if (args.includes('version')) console.log('etcdutl version: synthetic');
} else if (command === 'age') {
  process.stdin.resume();
  process.stdin.on('end', () => {
    if (mode === 'encrypt-failure') process.exit(1);
    process.stdout.write('age-encryption.org/v1\nsynthetic ciphertext\n');
  });
} else if (command === 'date') {
  console.log(args.some(arg => arg.includes('%N')) ? '20260922T180000.123456789Z' : args.includes('+%s') ? '1790092800' : '2026-09-22T18:00:00Z');
} else if (command === 'mountpoint') {
  process.exit(mode === 'unmounted' ? 1 : 0);
} else if (command === 'ssh') {
  process.stdout.write(mode === 'bad-format' ? 'unexpected plaintext\n' : 'age-encryption.org/v1\nsynthetic ciphertext\n');
  process.exit(mode === 'transfer-failure' ? 1 : 0);
} else if (command === 'sha256sum') {
  console.log('synthetic digest');
} else if (command === 'du') {
  console.log('4096\tmember');
} else if (command === 'df') {
  console.log('Available\n' + (mode === 'insufficient-space' ? '4096' : '10737418240'));
}
`;
  for (const command of ['crictl', 'age', 'flock', 'date', 'mountpoint', 'ssh', 'sync', 'find', 'sha256sum', 'du', 'df']) {
    writeFileSync(join(root, 'bin', command), mock, { mode: 0o755 });
  }
  writeFileSync(env.TEST_CALLS, '');
  const run = (file, mode = '', args = []) => spawnSync('bash', ['-euo', 'pipefail', file, ...args], {
    env: { ...env, TEST_MODE: mode }, encoding: 'utf8', maxBuffer: 1024 * 1024,
  });
  const calls = () => readFileSync(env.TEST_CALLS, 'utf8').trim().split('\n').filter(Boolean).map(line => JSON.parse(line));
  return { root, env, run, calls };
}

test('export validates and isolated-restores before encryption; stdout contains only ciphertext', t => {
  const f = fixture(t);
  const result = f.run(source);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, 'age-encryption.org/v1\nsynthetic ciphertext\n');
  const calls = f.calls();
  const restoreIndex = calls.findIndex(c => c.args.includes('restore'));
  assert.ok(restoreIndex > calls.findIndex(c => c.args.includes('status')));
  assert.ok(calls.findIndex(c => c.command === 'age') > restoreIndex);
  assert.deepEqual(readdirSync(f.env.ETCD_DATA_DIRECTORY), [], 'plaintext staging must be removed');
});

for (const mode of ['insufficient-space', 'multiple', 'save-failure', 'empty', 'restore-failure', 'encrypt-failure']) {
  test(`export fails closed and cleans its staging directory: ${mode}`, t => {
    const f = fixture(t);
    const result = f.run(source, mode);
    assert.notEqual(result.status, 0);
    assert.equal(result.stdout, '');
    assert.deepEqual(readdirSync(f.env.ETCD_DATA_DIRECTORY), []);
  });
}

test('export rejects all caller-supplied arguments', t => {
  const f = fixture(t);
  assert.notEqual(f.run(source, '', ['/arbitrary/path']).status, 0);
  assert.equal(f.calls().length, 0);
});

test('collector pins identity and server key, publishes ciphertext atomically, then prunes and updates metrics', t => {
  const f = fixture(t);
  const result = f.run(collector);
  assert.equal(result.status, 0, result.stderr);
  const files = readdirSync(f.env.BACKUP_DIRECTORY);
  assert.deepEqual(files, ['etcd-20260922T180000.123456789Z.tar.gz.age']);
  assert.equal(statSync(join(f.env.BACKUP_DIRECTORY, files[0])).mode & 0o777, 0o600);
  const calls = f.calls();
  const ssh = calls.find(c => c.command === 'ssh');
  for (const arg of ['StrictHostKeyChecking=yes', 'IdentityAgent=none', 'IdentitiesOnly=yes', 'UserKnownHostsFile=/dev/null', `GlobalKnownHostsFile=${f.env.BACKUP_KNOWN_HOSTS}`]) assert.ok(ssh.args.includes(arg));
  assert.deepEqual(ssh.args.slice(-2), ['etcd-snapshot@100.102.143.47', 'export-etcd-snapshot-v1']);
  assert.ok(calls.findIndex(c => c.command === 'find') > calls.findIndex(c => c.command === 'sha256sum'));
  assert.match(readFileSync(join(f.env.BACKUP_METRICS_DIRECTORY, 'etcd-indigo.prom'), 'utf8'), /cluster="indigo"} 1790092800/);
});

for (const mode of ['unmounted', 'transfer-failure', 'bad-format']) {
  test(`collector never publishes, prunes or marks success after ${mode}`, t => {
    const f = fixture(t);
    writeFileSync(join(f.env.BACKUP_DIRECTORY, 'etcd-previous.tar.gz.age'), 'old encrypted backup');
    const result = f.run(collector, mode);
    assert.notEqual(result.status, 0);
    assert.deepEqual(readdirSync(f.env.BACKUP_DIRECTORY), ['etcd-previous.tar.gz.age']);
    assert.deepEqual(readdirSync(f.env.BACKUP_METRICS_DIRECTORY), []);
    assert.ok(!f.calls().some(c => c.command === 'find'));
  });
}

test('publication refuses to overwrite an existing backup', t => {
  const f = fixture(t);
  const name = 'etcd-20260922T180000.123456789Z.tar.gz.age';
  writeFileSync(join(f.env.BACKUP_DIRECTORY, name), 'previous backup');
  assert.notEqual(f.run(collector).status, 0);
  assert.equal(readFileSync(join(f.env.BACKUP_DIRECTORY, name), 'utf8'), 'previous backup');
  assert.ok(!f.calls().some(c => c.command === 'find'));
});

test('Nix configuration enables one source and one collector without broad SSH or root login changes', () => {
  const module = read('modules/nixos/etcd-backup.nix');
  assert.match(module, /restrict,from=.*collectorAddress.*command=/);
  assert.match(module, /SSH_ORIGINAL_COMMAND:-.*!= export-etcd-snapshot-v1/);
  assert.match(module, /commands = \[\{ command = ''\$\{lib.getExe exporter\} ""''/);
  assert.doesNotMatch(module, /PermitRootLogin|wheelNeedsPassword|authorizedKeys.*allHosts|encryption-provider-config/);
  assert.match(module, /requires = \[ "var-lib-backup.mount" \]/);
  assert.match(module, /IPAddressDeny = "any"/);
  assert.match(module, /00,06,12,18:00:00/);
  assert.match(module, /retentionDays = mkOption \{ type = ints.positive; default = 31/);
  assert.match(read('hosts/srv-lx-k8s-indigo-control-01/backup.nix'), /etcdBackup.source/);
  assert.match(read('hosts/srv-lx-backup/etcd-backup.nix'), /etcdBackup.collector/);
  const inventory = read('profiles/kubernetes/indigo-backup.nix');
  assert.match(inventory, /recoveryRecipients = keys.groups.admins/);
  assert.match(inventory, /sourceAddress = "100.102.143.47"/);
  assert.match(inventory, /collectorAddress = "100.71.152.103"/);
});

test('real age encryption produces a recoverable archive containing only the snapshot and metadata', { skip: !process.env.AGE_TEST_BIN }, t => {
  const f = fixture(t);
  const age = process.env.AGE_TEST_BIN;
  const keygen = join(dirname(age), 'age-keygen');
  const identity = join(f.root, 'test-private-key');
  assert.equal(spawnSync(keygen, ['-o', identity]).status, 0);
  const recipient = spawnSync(keygen, ['-y', identity], { encoding: 'utf8' });
  assert.equal(recipient.status, 0);
  writeFileSync(f.env.AGE_RECIPIENTS_FILE, recipient.stdout);
  rmSync(join(f.root, 'bin', 'age'));
  symlinkSync(age, join(f.root, 'bin', 'age'));
  const result = spawnSync('bash', ['-euo', 'pipefail', source], { env: f.env, maxBuffer: 1024 * 1024 });
  assert.equal(result.status, 0, result.stderr.toString());
  const decrypted = spawnSync(age, ['-d', '-i', identity], { input: result.stdout });
  assert.equal(decrypted.status, 0);
  const contents = spawnSync('tar', ['-tzf', '-'], { input: decrypted.stdout, encoding: 'utf8' });
  assert.equal(contents.status, 0);
  assert.deepEqual(contents.stdout.trim().split('\n'), ['snapshot.db', 'snapshot-status.json', 'etcd-version.txt', 'manifest.json']);
});
