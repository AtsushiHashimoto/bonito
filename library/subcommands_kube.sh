function help_bonito_create_master_node {
  cat <<EOF
$subcommand adds the node (PC) to your cluster prepared by kubertenes.
before running the command, you need to install kubertenes, and set $BONITO_DIR/bonito.conf appropriately. 
EOF
}
function help_bonito_create_slave_node {
  cat <<EOF
$subcommand adds the node (PC) to your cluster prepared by kubertenes.
before running the command, you need to install kubertenes, and set $BONITO_DIR/bonito.conf appropriately. You also need to copy or syncronize $BONITO_DIR on the master node to this node PC. 
EOF
}

function bonito_create_master_node {
  kubeadm init --pod-network-cidr=$BONITO_POD_NETWORK_CIDR
  token=$(kubeadm token generate)
  kubeadm token create ${token} --print-join-command --ttl=0 > $BONITO_BIN_JOIN
  chmod a+x $BONITO_BIN_JOIN

  cp /etc/kubernetes/admin.conf $BONITO_K8S_CONFIG
  chown $(id -u):$(id -g) $BONITO_K8S_CONFIG
  chmod a+r $BONITO_K8S_CONFIG
  export KUBECONFIG=$BONITO_K8S_CONFIG

  for daemon in $BONITO_K8S_DAEMONSET; do
    echo kubectl create -f $daemon
  done
}

function bonito_create_slave_node {
  $BONITO_BIN_JOIN
}
