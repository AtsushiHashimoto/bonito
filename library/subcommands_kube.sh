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

function bonito_registry_yaml {
  echo $BONITO_DIR/projects/in-cluster-registry.yml
}
function bonito_cert_dir {
  echo $BONITO_DIR/cert
}
function bonito_create_certificate {
  cert_dir=$(bonito_cert_dir)
  bonito_confirm_overwrite $cert_dir/server.crt
  ret=$?
  if [ $ret -eq 0 ]; then
    days=3650 # 10 years
    mkdir -p $cert_dir
    cd $cert_dir
    openssl genrsa 2048 > server.key
    openssl req -new -key server.key > server.csr
    openssl x509 -days $days -req -signkey server.key < server.csr > server.crt.tmp
    mv server.crt.tmp server.crt
    cd - > /dev/null
  fi
}

function bonito_create_registry_yaml {
  bonito_create_certificate
  echo hoge
  cert_dir=$(bonito_cert_dir)
  cd $cert_dir > /dev/null
  export BONITO_TMP_CERT_BASE64=$(cat server.crt|base64 --w 0)
  export BONITO_TMP_KEY_BASE64=$(cat server.key|base64 --w 0)
  echo bonito_render $BONITO_TPL_REGIS
  bonito_render $BONITO_TPL_REGIS > $(bonito_registry_yaml)
  echo bonito_render done.
  if [ $is_verbose -eq 1 ]; then
    echo $(bonito_registry_yaml) is updated.
  fi
  export BONITO_TMP_CERT_BASE64=
  export BONITO_TMP_KEY_BASE64=
  cd - > /dev/null
}

function bonito_init_master_node {
  mkdir -p $BONITO_PV_SHARE_DIR
  mkdir -p $BONITO_PV_REGIS_DIR
  mkdir -p $BONITO_PV_HOME_DIR
  mkdir -p $BONITO_DIR/tls
  kubectl config set-context $(kubectl config current-context) --namespace=$BONITO_NAMESPACE
  for daemon in $BONITO_K8S_DAEMONSET; do
    echo kubectl apply -f $daemon
    kubectl apply -f $daemon
  done

  # create in-cluster private registry
  bonito_create_registry_yaml
  echo kubectl apply -f $(bonito_registry_yaml)
  kubectl apply -f $(bonito_registry_yaml)

  # render persistent volumes for gpgpu clusters
  echo bonito_load_pods
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
