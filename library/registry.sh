
function bonito_init_registry {
  mkdir -p $BONITO_
  #bonito_generate_certifications
  docker pull $BONITO_DOCKER_REGISTRY_IMAGE
  docker run --restart=always -v $BONITO_REGIS_DIR:$BONITO_REGIS_DIR --name bonito_registry $BONITO_DOCKER_REGISTRY_IMAGE
}

function bonito_generate_certification {
  echo "hoge"
}
