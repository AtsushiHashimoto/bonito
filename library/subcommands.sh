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
  image=$(bonito_image)

  # backup old image
  if [ $(bonito_image_exists) -eq 1 ]; then
    image_timestamped=$(bonito_image_custom $user $project $(bonito_timestamp_sec))
    docker tag $image $image_timestamped
    docker rmi $image
  fi

  if [ $(bonito_image_exists $base_image) -eq 0 ]; then
    bonito_warn "'$base_image' not found."
    echo $base_image | grep 'bonito' > /dev/null
    if [ $? -eq 1 ]; then
      bonito_info "Executing 'docker pull $base_image' may solve the problem."
    fi
    return 1
  fi

  dockerfile=$(bonito_create_dockerfile)
  args="--build-arg USER_NAME=$user --build-arg USER_ID=`id -u $user` --build-arg GROUP_ID=`id -g $user` --build-arg BASE_IMAGE=$base_image"
  if [ "x$HTTP_PROXY" != "x" ]; then
    args="$args --build-arg HTTP_PROXY=$HTTP_PROXY"
  fi
  echo docker build $args -f $dockerfile . -t $image
  docker build $args -f $dockerfile . -t $image
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
    echo docker rmi $(bonito_image)
    docker rmi $(bonito_image)
  fi
  home_dir=$(bonito_home)
  if [ $(bonito_file_exists $home_dir) -eq 1 ]; then
    bonito_info "home directory ($home_dir) is not deleted automatically. If you want to delete it, do manually."
  fi
}


###################
#####   RUN  ######
function print_options_bonito_run {
  cat <<EOF
    --command,-c      direct command executed in the container.
                      (Default: /bin/sh)
    --options,-o      additional options passed to 'docker run' execution.
                      (e.g. -o '-p 18888:8888' to connect host port to container's 8888 port.)
    --preset,-p      set options preset in environment.
                      (e.g. -p jupyter to add options set by 'export BONITO_PRESET_JUPYTER="-p 18888:8888"')
EOF
}

function help_bonito_run {
  help_bonito_basic "$(print_options_bonito_run)"
}

function bonito_run {
  image=$(bonito_image)

  # check if home directory exists or not.
  if [ $(bonito_file_exists $(bonito_home)) -eq 0 ]; then
    bonito_error "your home directory '$(bonito_home)' does not exists."
    return 1
  fi

  # always pull to update changes to images by `bonito snapshot`
  if [ "x$BONITO_REGIS_SERVER" != "x" ]; then
    docker pull $image
    res=$?
  fi
  if [ $res -eq 1 ]; then
    bonito_error "image name: $image not found. Did you create your image?"
    echo "Hint: command: $0 create --help"
    return 1
  fi

  # if command is directed, run it as a new container
  preset_=BONITO_PRESET_${preset^^}
  preset_=$(eval "echo \$$preset_")

  opt_="$BONITO_COMMON_RUN_OPT $BONITO_USER_RUN_OPT $opt $preset_ $(bonito_mount_option) $(bonito_port_option)"
  if [ $command != $BONITO_SHELL ]; then
    if [ "x$preset" != "x" ]; then
      container=$(bonito_container).$preset
    else
      container=$(bonito_container)-$(bonito_timestamp_msec)
    fi
    if [ "x$opt" == "x" ]; then
      if [ "x$preset_" == "x" ]; then
        opt_="$opt_ --rm"
      fi
    fi
    command="docker run $opt_ --name=$container -ti $image $command"
    echo $command
    $command
    return $?
  fi

  # if container is not exists, run the image.
  container=$(bonito_container)
  if [ $(bonito_container_exists) -eq 0 ]; then
    command="docker run $opt_ --name=$container -ti $image $command"
    echo $command
    $command
    echo docker run $opt_ --name=$container -ti $image $command
    docker run $opt_ --name=$container -ti $image $command
    return $?
  fi

  if [ "x$opt" != "x" ]; then
    bonito_warn "run option '$opt' is specified, but ignored."
    bonito_warn "To activate the options, you must shutdown the container in advance."
  fi

  # if image is exists, but not running, start it.
  if [ $(bonito_container_exists "--filter status=running") -eq 0 ]; then
    echo docker start $container
    docker start $container
  fi
  echo docker attach $container
  docker attach $container
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
  docker stop $tar > /dev/null
  docker rm $tar > /dev/null
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
  systemctl restart docker
}

#######################
##### START REGIS #####
function help_bonito_start_registry {
  help_bonito_admin
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
  help_bonito_admin
}

function bonito_stop_registry {
  if [ $(bonito_is_registry_server) -eq 0 ]; then
    bonito_error "registry can be stopped only on the registry server node ($BONITO_REGIS_SERVER)"
    return 1
  fi
  bonito_stop_registry_
}


########################
#####   ADD_USER   #####
function help_bonito_add_user {
  cat <<EOF
$(basename ${0}) ${subcommand}: $(echo \$exp_text_$subcommand)

Usage:
    sudo $(basename ${0}) $subcommand --user <user_name>]

Options:
    --user,-u      target user name.

EOF
}
function bonito_add_user {
  if [ "x" == "x$user" ]; then
    bonito_error "--user/-u must be specified with $subcommand"
    return 1
  fi
  gpasswd -a $user docker
  systemctl daemon-reload
  echo "restart dockerd by command:"
  echo " # systemctl restart docker "
  echo "Caution: this will stop all the running containers on the machine."

  if [ $(bonito_is_in_file $BONITO_USER_LIST $user) -eq 0 ]; then
    echo "$user $(expr 1 + $(cat $BONITO_USER_LIST | wc -l ))" >> $BONITO_USER_LIST
  fi
}
