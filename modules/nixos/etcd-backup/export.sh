if (( $# != 0 )); then
  echo 'The snapshot exporter does not accept arguments.' >&2
  exit 1
fi
umask 077
exec 9>"$ETCD_BACKUP_LOCK"
flock --nonblock 9

# Snapshot and isolated-restore staging share the data filesystem. Refuse to
# start unless it has room for both plus a conservative live-etcd reserve.
data_bytes=$(du --summarize --block-size=1 "$ETCD_DATA_DIRECTORY/member" | cut -f1)
available_bytes=$(df --block-size=1 --output=avail "$ETCD_DATA_DIRECTORY" | tail -n 1 | tr -d ' ')
if [[ ! "$data_bytes" =~ ^[0-9]+$ || ! "$available_bytes" =~ ^[0-9]+$ ]] \
  || (( available_bytes < data_bytes * 3 + 1073741824 )); then
  echo 'Insufficient free space for safe etcd snapshot and restore staging.' >&2
  exit 1
fi

# This directory is inside the existing etcd data mount, so the running
# container's version-matched etcdctl and etcdutl can access it.
temporary=$(mktemp -d "$ETCD_DATA_DIRECTORY/dsqr-backup.XXXXXXXXXX")
cleanup() {
  case "$temporary" in
    "$ETCD_DATA_DIRECTORY"/dsqr-backup.*) rm -rf -- "$temporary" ;;
    *) echo 'Refusing unexpected cleanup path.' >&2 ;;
  esac
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

cri() { crictl --config "$CRICTL_CONFIG" "$@"; }
container=$(cri ps --name '^etcd$' --state Running --quiet)
if [[ ! "$container" =~ ^[a-f0-9]+$ ]]; then
  echo 'Expected exactly one running etcd container.' >&2
  exit 1
fi
cri exec "$container" etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  --command-timeout=5m snapshot save "$temporary/snapshot.db" >&2
chmod 0600 "$temporary/snapshot.db"
test -s "$temporary/snapshot.db"
cri exec "$container" etcdutl snapshot status "$temporary/snapshot.db" --write-out=json > "$temporary/snapshot-status.json"
jq --exit-status '.revision > 0 and .totalKey > 0' "$temporary/snapshot-status.json" >/dev/null

# An isolated restore verifies the snapshot's integrity hash. No etcd process
# is started, and the live member directory is never a restore destination.
cri exec "$container" etcdutl snapshot restore "$temporary/snapshot.db" \
  --data-dir="$temporary/restore-check" >&2
cri exec "$container" etcdutl version > "$temporary/etcd-version.txt"
jq --null-input --arg cluster "$ETCD_CLUSTER_NAME" --arg created "$(date --utc +%FT%TZ)" \
  '{formatVersion: 1, cluster: $cluster, createdAt: $created, validation: "isolated-etcdutl-restore", scope: "etcd-only; PKI and encryption keys are separate recovery prerequisites"}' \
  > "$temporary/manifest.json"

# stdout is exclusively an encrypted archive. Neither SSH nor the collector
# ever receives plaintext database contents or the live encryption keyring.
tar --directory "$temporary" --create --gzip --file - \
  snapshot.db snapshot-status.json etcd-version.txt manifest.json \
  | age --encrypt --recipients-file "$AGE_RECIPIENTS_FILE"
