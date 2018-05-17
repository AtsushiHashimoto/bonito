function bonito_print_basic_options {
  cat <<EOF
    --user            direct project user name. (Default: $USER)
    --project         direct project name. (Default: $BONITO_DEFAULT_PROJ)
    --version         print $(basename ${0}) version
    --help, -h        print this
    --verbose,-v      print debug messages
    --debug           set -x
EOF
}

function help_bonito_basic {
  cat <<EOF
$(basename ${0}) ${subcommand}: $(eval "echo \$exp_text_$subcommand")

Usage:
    $(basename ${0}) $subcommand [<options>]

Options:
$(bonito_print_basic_options)
$1
EOF
}
###################
##### CREATE ######

function print_options_bonito_create {
  cat <<EOF
    --base_image,-b    direct base image of this project.
                      (Default: $BONITO_USER.$BONITO_PROJECT)
EOF
# default values for num_gpu,image,volume_size are defined in $BONITO_DIR/bin/bonito}
}

function help_bonito_create {
  help_bonito_basic "$(print_options_bonito_create)"
}

function bonito_create {
  bonito_create_home_dir
  if [ $? -gt 0 ]; then
    return 1
  fi

  bonito_create_image
  if [ $? -gt 0 ]; then
    return 1
  fi
}

function bonito_create_image {
  if [ $(bonito_image_exists) -eq 1 ]; then
    echo "Before creating a new image, delete existing image by 'bonito delete'"
    echo "Otherwise, you can create another project image by 'bonito create -p <other_project_name>'"
    return 1
  fi


  image_timestamped=$(bonito_image_custom $user $project $(bonito_timestamp_sec))
  image=$(bonito_image)
  docker tag $base_image $image_timestamped
  ret=$?
  if [ $ret -gt 0 ]; then
    bonito_error "Failed to tag base image ($base_image -> $image_timestamped)."
    return 1
  fi
  docker tag $image_timestamped $image
  ret=$?
  if [ $ret -gt 0 ]; then
    bonito_error "Failed to tag image with timestamp as latest ($image_timestamped -> $image)."
    return 1
  fi
  docker push $image
}

function bonito_create_home_dir {
  home_dir=$(bonito_home)
  if [ $(bonito_file_exists $home_dir) -eq 1 ]; then
    return 0
  fi
  base_dir=$(bonito_home_custom $BONITO_DEFAULT_USER)
  if [ $(bonito_file_exists $base_dir) -eq 0 ]; then
    bonito_error "Prepare default home directory to $base_dir".
    return 1
  fi
  mkdir $home_dir
  ret=$?
  if [ $ret -gt 0 ]; then
    bonito_error "Failed to create $home_dir."
    return 1
  fi
  rsync -av $base_dir/ $home_dir
  chown -R $USER:$USER $home_dir
}

###################
##### DELETE ######

function help_bonito_delete {
  help_bonito_basic ""
}

function bonito_delete {
  bonito_shutdown
  if [ $(bonito_image_exists) -eq 1 ]; then
    docker rmi $(bonito_image)
  fi
  home_dir=$(bonito_home)
  if [ $(bonito_file_exists $home_dir) -eq 1 ]; then
    bonito_warn "home directory ($home_dir) is not deleted. If you want to delete it, do manually."
  fi
}

###################
#### SNAPSHOT #####

function help_bonito_snapshot {
  help_bonito_basic ""
}
function bonito_snapshot {
  image_timestamped=$(bonito_image_custom $user $project $(bonito_timestamp_sec))
  image_latest=$(bonito_image)
  if [ $(bonito_container_exists) -eq 0 ]; then
    bonito_error "Container '$(bonito_container)' not found."
    return 1
  fi
  docker commit $(bonito_container) $image_timestamped
  docker tag $image_timestamped $image_latest
  docker push $image_latest
}



###################
#####   RUN  ######
function print_options_bonito_run {
  cat <<EOF
    --command          direct command executed in the container.
                      (Default: /bin/sh)
EOF
}

function help_bonito_run {
  help_bonito_basic "$(print_options_bonito_run)"
}

function bonito_run {
  image=$(bonito_image)

  # always pull to update changes to images by `bonito snapshot`
  docker pull $image
  res=$?
  if [ res -eq 1 ]; then
    bonito_error "image name: $image not found. Did you create your image?"
    echo "Hint: command: $0 create --help"
    return 1
  fi

  # if command is directed, run it as a new container
  if [ $command != $BONITO_SHELL ]; then
    container=$(bonito_container)-$(bonito_timestamp_msec)
    docker run $BONITO_RUN_OPT --name=$container $(bonito_mount_option) $(bonito_port_option) -ti $image $command
    return $?
  fi

  # if image is not exists, run it.
  if [ $(bonito_container_exists) -eq 0 ]; then
    docker run $BONITO_RUN_OPT --name=$(bonito_container) $(bonito_mount_option) $(bonito_port_option) -ti $image $command
    return $?
  fi

  # if image is exists, but not running, start it.
  if [ $(bonito_container_exists "--filter status=runnning") -eq 0 ]; then
    docker start $image
  fi
  docker attach $image
  return $?
}

###################
#### SHUTDOWN #####

function help_bonito_shutdown {
  help_bonito_basic shutdown "shutdown running container." ""
}

function bonito_shutdown {
  if [ $(bonito_container_exists) -eq 0 ]; then
    # do nothing when no containers exists
    bonito_warn "Container '$(bonito_container)' not found."
    return 0
  fi
  tar=$(bonito_container)
  docker stop $tar
  docker rm $tar
}

###################
##### REBOOT ######

function help_bonito_reboot {
  help_bonito_basic reboot "reboot (shutdown/create) the project pod." ""
}

function bonito_reboot {
  bonito_shutdown
  bonito_run
}

################
##### init #####
function help_bonito_admin {
  cat <<EOF
$(basename ${0}) ${subcommand}: $(echo \$exp_text_$subcommand)

Usage:
    sudo $(basename ${0}) $subcommand
EOF
}

function help_bonito_init {
  help_bonito_admin
}

function bonito_init {
  bonito_setup_registry
  systemctl daemon-reload
  hostname=$(hostname)
}

#######################
##### START REGIS #####
function help_bonito_start_registry {
  help_bonito_adm
}

function bonito_start_registry {
  if [ $(bonito_is_registry_server) -eq 0 ]; then
    bonito_error "registry can be started only on the registry server node ($BONITO_REGIS_SERVER)"
    return 1
  fi
  bonito_start_registry_
}

#######################
##### START REGIS #####
function help_bonito_stop_registry {
  help_bonito_adm
}

function bonito_stop_registry {
  if [ $(bonito_is_registry_server) -eq 0 ]; then
    bonito_error "registry can be stopped only on the registry server node ($BONITO_REGIS_SERVER)"
    return 1
  fi
  bonito_stop_registry_

}
