import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { mkdtempSync, readFileSync, readdirSync, rmSync, statSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { providerConfigs, renderConfigs } from '../packages/kubeadm-secrets/render-config.mjs';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');
const module = read('modules/nixos/kubeadm-encryption.nix');
const kubeadm = read('modules/nixos/kubeadm.nix');
const keyring = () => ({ version: 1, cluster: 'indigo', keys: [{ name: 'indigo-v1', secret: randomBytes(32).toString('base64') }] });
function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'kubeadm-encryption-test-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const key = join(root, 'keyring.json');
  const directory = join(root, 'providers');
  const data = keyring();
  writeFileSync(key, JSON.stringify(data), { mode: 0o600 });
  return { root, key, directory, data };
}

test('stages preserve readers before changing writers; Secrets only', () => {
  const data = keyring();
  const configs = providerConfigs(data, 'indigo');
  assert.deepEqual(Object.keys(configs), ['read-compatible', 'encrypt', 'enforced']);
  for (const config of Object.values(configs)) {
    assert.equal(config.apiVersion, 'apiserver.config.k8s.io/v1');
    assert.equal(config.kind, 'EncryptionConfiguration');
    assert.equal(config.resources.length, 1);
    assert.deepEqual(config.resources[0].resources, ['secrets']);
    assert.deepEqual(config.resources[0].providers.find(p => p.secretbox).secretbox.keys, data.keys);
  }
  assert.deepEqual(configs['read-compatible'].resources[0].providers.map(Object.keys), [['identity'], ['secretbox']]);
  assert.deepEqual(configs.encrypt.resources[0].providers.map(Object.keys), [['secretbox'], ['identity']]);
  assert.deepEqual(configs.enforced.resources[0].providers.map(Object.keys), [['secretbox']]);
});

test('all stages share ordered keys without silently dropping recovery keys', () => {
  const data = keyring();
  data.keys.unshift({ name: 'indigo-v2', secret: randomBytes(32).toString('base64') });
  for (const config of Object.values(providerConfigs(data, 'indigo'))) {
    assert.deepEqual(config.resources[0].providers.find(p => p.secretbox).secretbox.keys, data.keys);
  }
});

test('invalid, cross-cluster and duplicate keyrings are rejected', () => {
  assert.throws(() => providerConfigs(keyring(), 'another-cluster'));
  for (const secret of ['', 'not-base64', randomBytes(31).toString('base64')]) {
    const data = keyring();
    data.keys[0].secret = secret;
    assert.throws(() => providerConfigs(data, 'indigo'));
  }
  const data = keyring();
  data.keys.push(data.keys[0]);
  assert.throws(() => providerConfigs(data, 'indigo'));
});

test('runtime files are private JSON and contain only whitelisted key fields', t => {
  const { key, directory, data } = fixture(t);
  data.keys[0].untrusted = 'ignored';
  writeFileSync(key, JSON.stringify(data));
  renderConfigs(key, 'indigo', directory);
  assert.equal(statSync(directory).mode & 0o777, 0o700);
  assert.deepEqual(readdirSync(directory).sort(), ['encrypt.json', 'enforced.json', 'read-compatible.json']);
  for (const file of readdirSync(directory)) {
    assert.equal(statSync(join(directory, file)).mode & 0o777, 0o400);
    const config = JSON.parse(readFileSync(join(directory, file), 'utf8'));
    const keys = config.resources[0].providers.find(p => p.secretbox).secretbox.keys;
    assert.deepEqual(Object.keys(keys[0]), ['name', 'secret']);
  }
});

test('rerendering replaces files atomically without removing older-stage paths', t => {
  const { key, directory } = fixture(t);
  renderConfigs(key, 'indigo', directory);
  const data = keyring();
  writeFileSync(key, JSON.stringify(data));
  renderConfigs(key, 'indigo', directory);
  for (const stage of ['read-compatible', 'encrypt', 'enforced']) {
    const file = join(directory, `${stage}.json`);
    assert.equal(statSync(file).mode & 0o777, 0o400);
    assert.deepEqual(JSON.parse(readFileSync(file, 'utf8')), providerConfigs(data, 'indigo')[stage]);
  }
  assert.equal(readdirSync(directory).length, 3);
});

test('invalid input leaves every previously usable provider file untouched', t => {
  const { key, directory } = fixture(t);
  renderConfigs(key, 'indigo', directory);
  const before = readdirSync(directory).map(file => readFileSync(join(directory, file), 'utf8'));
  writeFileSync(key, '{malformed secret data');
  assert.throws(() => renderConfigs(key, 'indigo', directory));
  assert.deepEqual(readdirSync(directory).map(file => readFileSync(join(directory, file), 'utf8')), before);
});

test('renderer refuses a symlink output directory', t => {
  const { key, directory, root } = fixture(t);
  symlinkSync(root, directory);
  assert.throws(() => renderConfigs(key, 'indigo', directory));
  assert.equal(readdirSync(root).filter(name => name.endsWith('.json')).length, 1);
});

test('CLI errors cannot disclose secret values or JSON parser excerpts', t => {
  const { key, root, data } = fixture(t);
  const result = spawnSync(process.execPath, [new URL('../packages/kubeadm-secrets/render-config.mjs', import.meta.url).pathname, key, 'indigo', root], { encoding: 'utf8' });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  assert.equal(result.stderr, 'Kubernetes encryption configuration preparation failed; key material suppressed.\n');
  assert.ok(!result.stderr.includes(data.keys[0].secret));
});

test('agenix and runtime rendering use root-only files with both supported boot orderings', () => {
  assert.match(module, /file = cfg.keyringFile;\s*owner = "root";\s*group = "root";\s*mode = "0400";/);
  assert.match(module, /system.activationScripts.kubeadmEncryption = mkIf \(!sysusers\)/);
  assert.match(module, /deps = \[ "agenix" \]/);
  assert.match(module, /after = lib.optional sysusers "agenix-install-secrets.service"/);
  assert.match(module, /requires = lib.optional sysusers "agenix-install-secrets.service"/);
  assert.match(module, /RuntimeDirectoryPreserve = true/);
  assert.match(module, /RuntimeDirectoryMode = "0700"/);
  assert.match(module, /restartTriggers = \[ cfg.keyringFile \]/);
  assert.match(module, /systemd.services.kubelet = \{\s*requires = \[ "kubeadm-encryption.service" \];\s*after = \[ "kubeadm-encryption.service" \]/);
  assert.doesNotMatch(module, /readFile.*keyringFile|kubeadm init phase|manifests\/kube-apiserver|ExecStop/);
});

test('API provider config is stage-specific, opt-in, mounted read-only and not auto-reloaded', () => {
  assert.match(kubeadm, /optionals cfg.encryption.enable \[\s*\{\s*name = "encryption-provider-config";\s*value = "\/run\/kubernetes-encryption\/\$\{cfg.encryption.stage\}.json"/);
  assert.match(kubeadm, /name = "encryption-provider-config-automatic-reload";\s*value = "false"/);
  assert.match(kubeadm, /name = "encryption-config";\s*hostPath = "\/run\/kubernetes-encryption";\s*mountPath = "\/run\/kubernetes-encryption";\s*readOnly = true;\s*pathType = "Directory"/);
  assert.match(module, /default = "read-compatible"/);
  assert.match(module, /kubeadm.role == "control-plane"/);
});

test('only Indigo control planes opt in, with one shared age file and enforced encrypted reads', () => {
  const optedIn = readdirSync(new URL('../hosts/', import.meta.url)).filter(name => {
    try { return read(`hosts/${name}/default.nix`).includes('profiles/kubernetes/indigo-encryption.nix'); }
    catch (error) { if (error.code === 'ENOENT') return false; throw error; }
  }).sort();
  assert.deepEqual(optedIn, ['srv-lx-k8s-indigo-control-01', 'srv-lx-k8s-indigo-control-02', 'srv-lx-k8s-indigo-control-03']);
  const profile = read('profiles/kubernetes/indigo-encryption.nix');
  assert.match(profile, /keyringFile = .\/indigo-encryption-keyring.age/);
  assert.match(profile, /stage = "enforced"/);
});
