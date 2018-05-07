function bonito_add_user () {
  gpasswd -a $user docker
  echo "export KUBECONFIG=$BONITO_DIR/admin.conf"
  
}


function bonito_rm_registry () {
  if [[ $BONITO_REG_HOST = "" ]]; then
    echo "WARNING: BONITO_REG_HOST is not set!"
  fi  
  reg_containers=$(docker ps -a -q --filter "name=$BONITO_REG_NAME")
  if [[ $reg_containers = "" ]]; then
    echo 1 > /dev/null
  else
    docker rm $reg_containers > /dev/null
  fi
}	
function bonito_run_registry () {
  if [[ $BONITO_REG_HOST = "" ]]; then
    echo 1 > /dev/null
  else
    is_running=$(bonito_is_registry_alive)
    if [ $is_running -eq 0 ]; then
      bonito_rm_registry
      docker run -d -p $BONITO_REG_PORT:5000 --name=$BONITO_REG_NAME registry:$BONITO_REG_VER 
    fi
  fi
}

function bonito_is_registry_alive () {
  containers=$(docker ps -a --format "{{.Names}}" --filter status=running --filter name=$BONITO_REG_NAME)
  if [[ $containers = "" ]]; then
    echo 0
  else
    echo 1
  fi
}  
