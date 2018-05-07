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

function bonito_init_secure_docker_tls_access {
  tls_dir=$BONITO_DIR/tls
  days=365

  cd $tls_dir

  openssl genrsa -aes -out ca-key.pem 4096
  openssl genrsa req -new -x509 -days $days -key ca-key.pem -sha256 -out ca.pem

  openssl genrsa -out server-key.pem 4096
  openssl req -sha256 -new -key server-key.pem -out server.csr

  echo subjectAltName = IP:192.168.56.100,IP:127.0.0.1 > extfile.cnf
  openssl x509 -req -days $days -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server.pem -extfile extfile.cnf
    

  cd -
}

function bonito_init_master_node {
  for daemon in $BONITO_K8S_DAEMONSET; do
    echo kubectl apply -f $daemon
    kubectl apply -f $daemon
  done

  # render persistent volumes for gpgpu clusters
  bonito_load_pods
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
  bonito_init_master_node
}

function bonito_load_pods {
  for line in $(cat $BONITO_DIR/bonito-load.dat); do
    line=$BONITO_DIR/$line
    tmpfile=$TMPDIR/$(basename $line)
    if [ "x$is_verbose" == "x1" ]; then
      echo $line
      echo $tmpfile
    fi
    bonito_render $line > $tmpfile
    if [ "x$is_verbose" == "x1" ]; then
      echo kubectl apply -f $tmpfile
    fi
    kubectl apply -f $tmpfile
    echo
  done
}
function bonito_unload_pods {
  dat=$BONITO_DIR/bonito-load.dat
  if type "tac" > /dev/null 2>&1
  then
    list=$(tac $dat)
  else
    nlines=$(cat $dat | wc -l)
    list=$(tail -n $nlines -r $dat)
  fi

  for line in $list; do
    echo kubectl delete -f $line
    kubectl delete -f $line
    echo "" #line space
  done

}
function bonito_reload_pods {
  bonito_unload_pods
  bonito_load_pods
}

function bonito_create_slave_node {
  $BONITO_BIN_JOIN
}
