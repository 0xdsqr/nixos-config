# Invoked by the root kubelet preStart with paths supplied by NixOS.
set -euo pipefail
base=$1
overlay=$2
output=$3
test -f "$base"
test ! -L "$base"
test -f "$overlay"
test ! -L "$output"
yq -e '.kind == "KubeletConfiguration" and .apiVersion == "kubelet.config.k8s.io/v1beta1"' "$base" >/dev/null
umask 077
temporary=$(mktemp "${output}.XXXXXX")
trap 'rm -f "$temporary"' EXIT
# Preserve kubeadm's networking, authentication, rotation and other fields.
# A separate /run file makes disabling this overlay a clean configuration rollback.
# JSON input can give the merged YAML a flow-style root ({unquoted: keys}).
# Kubernetes detects the leading brace as JSON and rejects that YAML form.
# Emit strict JSON explicitly; Kubernetes accepts it regardless of file suffix.
yq eval-all -o=json 'select(fileIndex == 0) * select(fileIndex == 1)' "$base" "$overlay" > "$temporary"
yq -e '.kind == "KubeletConfiguration" and .authentication.anonymous.enabled == false and .authorization.mode == "Webhook"' "$temporary" >/dev/null
chown --reference="$base" "$temporary"
chmod 0600 "$temporary"
chmod 0600 "$base"
mv -f "$temporary" "$output"
trap - EXIT
