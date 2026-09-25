import { randomUUID } from 'node:crypto';
import { chmodSync, closeSync, fsyncSync, lstatSync, mkdirSync, openSync, readFileSync, renameSync, unlinkSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateKeyring } from './keyring.mjs';

export function providerConfigs(keyring, cluster) {
  const { keys } = validateKeyring(keyring, cluster);
  const secretbox = { secretbox: { keys: keys.map(({ name, secret }) => ({ name, secret })) } };
  return Object.fromEntries([
    ['read-compatible', [{ identity: {} }, secretbox]],
    ['encrypt', [secretbox, { identity: {} }]],
    ['enforced', [secretbox]],
  ].map(([stage, providers]) => [stage, {
    apiVersion: 'apiserver.config.k8s.io/v1',
    kind: 'EncryptionConfiguration',
    resources: [{ resources: ['secrets'], providers }],
  }]));
}

// Render every stage so an existing static manifest survives a reboot between
// the NixOS switch and explicit kubeadm manifest regeneration. No key reaches
// stdout, argv, environment variables, the Nix store, or persistent storage.
export function renderConfigs(keyringPath, cluster, directory) {
  // Validate all input before changing any provider files; parser errors may
  // contain key material and must only reach the generic CLI error below.
  const configs = providerConfigs(JSON.parse(readFileSync(keyringPath, 'utf8')), cluster);
  mkdirSync(directory, { recursive: true, mode: 0o700 });
  const stat = lstatSync(directory);
  if (!stat.isDirectory() || stat.uid !== process.getuid()) throw new Error('Unsafe output directory.');
  chmodSync(directory, 0o700);
  for (const [stage, config] of Object.entries(configs)) {
    const target = join(directory, `${stage}.json`);
    const temporary = join(directory, `.${stage}-${randomUUID()}`);
    let fd;
    try {
      fd = openSync(temporary, 'wx', 0o400);
      writeFileSync(fd, JSON.stringify(config) + '\n');
      fsyncSync(fd);
      closeSync(fd);
      fd = undefined;
      renameSync(temporary, target);
    } finally {
      if (fd !== undefined) closeSync(fd);
      try { unlinkSync(temporary); } catch (error) { if (error.code !== 'ENOENT') throw error; }
    }
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  try {
    const [keyring, cluster, directory, ...extra] = process.argv.slice(2);
    if (process.getuid() !== 0 || !keyring || !cluster || directory !== '/run/kubernetes-encryption' || extra.length) {
      throw new Error('Invalid renderer invocation.');
    }
    renderConfigs(keyring, cluster, directory);
  } catch {
    console.error('Kubernetes encryption configuration preparation failed; key material suppressed.');
    process.exitCode = 1;
  }
}
