
function bonito_start_registry_ {
  #bonito_generate_certifications
  if [ $(bonito_image_exists $BONITO_REGIS_IMAGE) -eq 0 ]; then
    docker pull $BONITO_REGIS_IMAGE
  fi
  tar="bonito_registry"
  docker ps -a --format '{{.Names}}' --filter name=$tar | grep $tar
  ret=$?
  if [ $ret -eq 0 ]; then
    bonito_warn "docker registry for bonito is already running."
    return 0
  fi
  docker run -d -p $BONITO_REGIS_PORT:5000 --restart=always -v $BONITO_REGIS_DIR:$BONITO_REGIS_DIR --name bonito_registry $BONITO_REGIS_IMAGE
}

function bonito_stop_registry_ {
  tar="bonito_registry"
  docker ps -a --format '{{.Names}}' --filter name=$tar | grep $tar
  ret=$?
  if [ $ret -eq 1 ]; then
    bonito_warn "docker registry for bonito is not running."
    return 0
  fi
  docker update --restart=no bonito_registry > /dev/null
  docker stop bonito_registry > /dev/null
  docker rm bonito_registry > /dev/null
}

function bonito_setup_registry {
  json=/etc/docker/daemon.json
  bonito_confirm_overwrite $json
  ret=$?
  if [ $ret -gt 0 ]; then
    return 0
  fi
  echo { \"insecure-registries\":[\"$BONITO_REGIS_SERVER:$BONITO_REGIS_PORT\"] } > $json
}
