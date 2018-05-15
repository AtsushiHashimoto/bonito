
function bonito_start_registry {
  mkdir -p $BONITO_REGIS_DIR
  #bonito_generate_certifications
  docker pull $BONITO_DOCKER_REGIS_IMAGE
  docker run -d -p $BONITO_REGIS_PORT:5000 --restart=always -v $BONITO_REGIS_DIR:$BONITO_REGIS_DIR --name bonito_registry $BONITO_DOCKER_REGIS_IMAGE
}
function bonito_stop_registry {
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
