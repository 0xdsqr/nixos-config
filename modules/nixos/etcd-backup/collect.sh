umask 077
if ! mountpoint --quiet "$BACKUP_MOUNT"; then
  echo 'The backup data filesystem is not mounted; refusing to write to the root disk.' >&2
  exit 1
fi
test -d "$BACKUP_DIRECTORY"
temporary=$(mktemp "$BACKUP_DIRECTORY/.incoming.XXXXXXXXXX")
trap 'rm -f -- "$temporary"' EXIT
trap 'exit 1' HUP INT TERM

ssh -F /dev/null -T \
  -i /etc/ssh/ssh_host_ed25519_key \
  -o BatchMode=yes -o IdentitiesOnly=yes -o IdentityAgent=none \
  -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
  -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/dev/null \
  -o GlobalKnownHostsFile="$BACKUP_KNOWN_HOSTS" \
  "etcd-snapshot@$BACKUP_SOURCE" export-etcd-snapshot-v1 > "$temporary"
test -s "$temporary"
if [[ "$(head -n 1 "$temporary")" != 'age-encryption.org/v1' ]]; then
  echo 'The exporter did not return an age-encrypted archive.' >&2
  exit 1
fi
sync -f "$temporary"
final="$BACKUP_DIRECTORY/etcd-$(date --utc +%Y%m%dT%H%M%S.%NZ).tar.gz.age"
# Hard-link publication is atomic and refuses to overwrite an existing backup.
ln -- "$temporary" "$final"
rm -f -- "$temporary"
sync -f "$BACKUP_DIRECTORY"
sha256sum "$final"

# Retention runs only after a new backup has completed successfully.
find "$BACKUP_DIRECTORY" -maxdepth 1 -type f -name 'etcd-*.tar.gz.age' \
  -mtime "+$BACKUP_RETENTION_DAYS" -delete

metric=$(mktemp "$BACKUP_METRICS_DIRECTORY/.etcd-$ETCD_CLUSTER_NAME.XXXXXXXXXX")
printf '%s\n' \
  '# HELP dsqr_etcd_backup_last_success_timestamp_seconds Last successfully collected validated encrypted etcd snapshot.' \
  '# TYPE dsqr_etcd_backup_last_success_timestamp_seconds gauge' \
  "dsqr_etcd_backup_last_success_timestamp_seconds{cluster=\"$ETCD_CLUSTER_NAME\"} $(date +%s)" > "$metric"
chmod 0644 "$metric"
mv -- "$metric" "$BACKUP_METRICS_DIRECTORY/etcd-$ETCD_CLUSTER_NAME.prom"
