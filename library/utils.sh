function bonito_add_user () {
  gpasswd -a $user docker
  echo "export KUBECONFIG=$BONITO_DIR/admin.conf"
  
}

