import { randomBytes } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, relative, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export function validateKeyring(keyring, cluster) {
  if (keyring.version !== 1 || keyring.cluster !== cluster || !Array.isArray(keyring.keys) || keyring.keys.length === 0) {
    throw new Error('Invalid recovery keyring metadata.');
  }
  const names = new Set();
  for (const key of keyring.keys) {
    if (typeof key.name !== 'string' || !/^[a-z0-9][a-z0-9-]*$/.test(key.name) || names.has(key.name)) {
      throw new Error('Invalid or duplicate encryption key name.');
    }
    if (typeof key.secret !== 'string' || Buffer.from(key.secret, 'base64').length !== 32 || Buffer.from(key.secret, 'base64').toString('base64') !== key.secret) {
      throw new Error('Encryption keys must be exactly 32 random bytes, encoded as canonical base64.');
    }
    names.add(key.name);
  }
  return keyring;
}

// Never forward subprocess output: decryption stdout and clipboard stdin contain secrets.
export function runKeyring({ registry, age, args, root = process.cwd() }, dependencies = {}) {
  const run = dependencies.run ?? spawnSync;
  const random = dependencies.random ?? randomBytes;
  const log = dependencies.log ?? console.log;
  const [operation, cluster, identity, ...extra] = args;
  if (!['init', 'copy-recovery'].includes(operation) || !Object.hasOwn(registry, cluster) || extra.length || (operation === 'init' && identity) || (operation === 'copy-recovery' && !identity)) {
    throw new Error('Usage: kubeadm-secrets init CLUSTER | copy-recovery CLUSTER SSH_IDENTITY_FILE');
  }
  if (!existsSync(resolve(root, 'secrets.nix')) || !existsSync(resolve(root, 'profiles/kubernetes/encryption-recipients.nix'))) {
    throw new Error('Run this command from the nixos-config repository root.');
  }
  const entry = registry[cluster];
  const destination = resolve(root, entry.file);
  const relativePath = relative(resolve(root), destination);
  if (isAbsolute(entry.file) || relativePath.startsWith('..') || !existsSync(dirname(destination)) || !Array.isArray(entry.publicKeys) || !entry.publicKeys.length) {
    throw new Error('Invalid encrypted-keyring destination or recipients.');
  }

  let plaintext;
  if (operation === 'init') {
    if (existsSync(destination)) {
      throw new Error('The encrypted keyring already exists; refusing to replace it. Use copy-recovery to recover the existing record.');
    }
    const keyring = validateKeyring({
      version: 1,
      cluster,
      keys: [{ name: `${cluster}-v1`, secret: random(32).toString('base64') }],
    }, cluster);
    plaintext = JSON.stringify(keyring, null, 2) + '\n';
    const encrypted = run(age, ['--encrypt', '--armor', ...entry.publicKeys.flatMap(key => ['--recipient', key])], {
      input: plaintext,
      encoding: 'utf8',
      maxBuffer: 1024 * 1024,
    });
    if (encrypted.error || encrypted.status !== 0 || !encrypted.stdout?.startsWith('-----BEGIN AGE ENCRYPTED FILE-----')) {
      throw new Error('Encryption failed; no keyring file was created.');
    }
    // Exclusive creation also protects against another invocation racing this one.
    writeFileSync(destination, encrypted.stdout, { flag: 'wx', mode: 0o600 });
    log(`Created encrypted keyring: ${entry.file}`);
  } else {
    const decrypted = run(age, ['--decrypt', '--identity', identity, destination], {
      encoding: 'utf8',
      maxBuffer: 1024 * 1024,
    });
    if (decrypted.error || decrypted.status !== 0) {
      throw new Error('Recovery decryption failed; clipboard was not changed. Check your SSH identity file.');
    }
    // Do not surface JSON parser errors, which can quote secret input.
    let keyring;
    try { keyring = JSON.parse(decrypted.stdout); } catch { throw new Error('Invalid recovery record; clipboard was not changed.'); }
    plaintext = JSON.stringify(validateKeyring(keyring, cluster), null, 2) + '\n';
  }
  const copied = run('/usr/bin/pbcopy', [], { input: plaintext, encoding: 'utf8' });
  if (copied.error || copied.status !== 0) {
    throw new Error('Clipboard copy failed. The encrypted file is retained; use copy-recovery CLUSTER SSH_IDENTITY_FILE on your Mac. Do not delete or regenerate it.');
  }
  log('Recovery keyring copied to your clipboard. Save it in a 1Password Secure Note; do not paste it into chat.');
  log('Nothing was deployed. Keep this keyring with your etcd recovery backups.');
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  try {
    const [registryPath, age, ...args] = process.argv.slice(2);
    const registry = JSON.parse(readFileSync(registryPath, 'utf8'));
    runKeyring({ registry, age, args });
  } catch (error) {
    // Only our controlled validation messages should be useful; filesystem errors don't contain plaintext.
    console.error(error.message);
    process.exitCode = 1;
  }
}
