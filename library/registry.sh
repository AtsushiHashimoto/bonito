
function bonito_init_registry {
  bonito_generate_certifications
  docker pull $BONITO_DOCKER_REGISTRY_IMAGE
  docker run --restart=always --name bonito_registry $BONITO_DOCKER_REGISTRY_IMAGE
}

function bonito_generate_certification {
  
}
