#!/usr/bin/env -S nu

let script_dir = $env.FILE_PWD
let source_config = ($script_dir | path join "init.yaml")
let target_config = "/root/kubeadm-init.yaml"
let cri_socket = "unix:///run/containerd/containerd.sock"
let kube_dir = ($env.HOME | path join ".kube")
let kube_config = ($kube_dir | path join "config")
let uid = (^id -u | str trim)
let gid = (^id -g | str trim)

if not ($source_config | path exists) {
  print $"missing kubeadm config: ($source_config)"
  exit 1
}

if ((which kubeadm | length) == 0) {
  print "kubeadm is not installed on this host"
  exit 1
}

print $"Copying kubeadm config to ($target_config)"
^sudo install -m 0600 $source_config $target_config

print "Pulling Kubernetes control-plane images"
^sudo kubeadm config images pull --cri-socket $cri_socket

print "Validating kubeadm config"
^sudo kubeadm config validate --config $target_config

print "Initializing cluster"
^sudo kubeadm init --config $target_config

print $"Writing kubectl config to ($kube_config)"
if not ($kube_dir | path exists) {
  mkdir $kube_dir
}
^sudo cp /etc/kubernetes/admin.conf $kube_config
^sudo chown $"($uid):($gid)" $kube_config

print "Checking nodes"
^kubectl get nodes -o wide

print "Checking pods"
^kubectl get pods -A

print ""
print "Bootstrap complete."
print "Next step: apply the cluster platform stack from homelab IaC."
print "Expected order there: Cilium, MetalLB, Traefik, kube-state-metrics, then app releases."
