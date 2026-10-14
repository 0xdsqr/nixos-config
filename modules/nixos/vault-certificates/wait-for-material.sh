if [[ $# -ne 7 ]]; then
  echo "Expected owner, group, certificate mode, private mode, cache, certificate and key paths." >&2
  exit 64
fi

owner=$1
group=$2
certificate_mode=${3#0}
private_mode=${4#0}
cache=$5
certificate=$6
key=$7

material_ready() {
  local file=$1 mode=$2 metadata
  [[ -s "$file" ]] || return 1
  metadata=$(stat -Lc '%U:%G:%a' "$file") || return 1
  [[ "$metadata" == "$owner:$group:$mode" ]]
}

# A previous generation may have nonempty files with obsolete permissions.
# Wait for the renderer to finish ownership/mode updates, not just file existence.
for _ in {1..60}; do
  if material_ready "$cache" "$private_mode" &&
    material_ready "$certificate" "$certificate_mode" &&
    material_ready "$key" "$private_mode"; then
    exit 0
  fi
  sleep 1
done

echo "Timed out waiting for certificate material with the configured ownership and modes." >&2
exit 1
