
function bonito_start_registry_ {
  #bonito_generate_certifications
  if [ $(bonito_image_exists $BONITO_REGIS_IMAGE) -eq 0 ]; then
    docker pull $BONITO_REGIS_IMAGE
  fi
  tar="bonito_registry"
  docker ps -a --format '{{.Names}}' --filter name=$tar | grep $tar > /dev/null
  ret=$?
  if [ $ret -eq 0 ]; then
    bonito_warn "docker registry for bonito is already running."
    return 0
  fi
  if [ $(bonito_file_exists $BONITO_REGIS_DIR) -eq 0 ]; then
    mkdir -p $BONITO_REGIS_DIR
  fi
  docker run -d -p $BONITO_REGIS_PORT:5000 --restart=always -v $BONITO_REGIS_DIR:/var/lib/registry --name bonito_registry $BONITO_REGIS_IMAGE
}

function bonito_stop_registry_ {
  tar="bonito_registry"
  docker ps -a --format '{{.Names}}' --filter name=$tar | grep $tar > /dev/null
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
  cat <<EOF > $json
{
  "insecure-registries":["$BONITO_REGIS_SERVER:$BONITO_REGIS_PORT"],
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}
EOF
  conf=/etc/systemd/system/docker.service.d/no-proxy.conf
  bonito_confirm_overwrite $conf
  ret=$?
  if [ $ret -gt 0 ]; then
    return 0
  fi
  cat << EOF >> $conf
[Service]
Environment="NO_PROXY=localhost,$BONITO_REGIS_SERVER"
EOF
}
