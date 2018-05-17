function bonito_error {
  echo "ERROR: $1" >&2
}

function bonito_warn {
  echo "WARNING: $1" >&2
}

function bonito_image_exists {
  if [ $# -eq 0 ]; then
    tar=$image
  else
    tar=$1
  fi
  docker images --format "{{.Repository}}:{{.Tag}}" -a | grep $tar > /dev/null
  ret=$?
  if [ $ret -eq 0 ]; then
    echo 1
    return 0
  fi
  echo 0
  return 0
}

function bonito_base_image_exists {
  tar=$(bonito_image_custom $BONITO_DEFAULT_USER $project)
  bonito_image_exists $tar
}

function bonito_container_exists {
  if [ $# -gt 0 ]; then
    filter=$1
  fi
  tar=$(bonito_container)
  docker ps -a --format '{{.Names}}' $filter --filter name="/$tar\$" | grep $tar > /dev/null
  ret=$?
  if [ $ret -eq 0 ]; then
    echo 1
    return 0
  fi
  echo 0
  return 0
}



function bonito_image {
  bonito_image_custom $user $project $tag
}

function bonito_image_custom {
  if [ $# -lt 1 ]; then
    user_=$user
  else
    user_=$1
  fi
  if [ $# -lt 2 ]; then
    project_=$project
  else
    project_=$2
  fi
  if [ $# -lt 3 ]; then
    tag_=$tag
  else
    tag_=$3
  fi
  image=$BONITO_PREFIX/$user_/$project_:$tag_
  if [ "x$BONITO_REGIS_SERVER" == "x" ]; then
    echo $image
    return 0
  fi
  echo $BONITO_REGIS_SERVER:$BONITO_REGIS_PORT/$image
}

function bonito_container {
  echo $BONITO_PREFIX.$user.$project
}

function bonito_home_custom {
  user_=$1
  echo $BONITO_HOME_DIR/$user_
}
function bonito_home {
  bonito_home_custom $user $project
}

function bonito_mount_option {
  temp=${BONITO_MOUNTS}
  common_mount=""
  for v in ${temp[@]}; do
    v_=$(echo $v | sed -e "s/:ro//")
    common_mount="${common_mount} -v ${v_}:${v}"
  done
  echo "-v $(bonito_home)/:/root ${common_mount}"
}

function bonito_port_option {
  temp=${BONITO_PORTS}
  common_port=""
  for p in ${temp[@]}; do
    host_port=$(echo $p | sed -e "s/:.*//")
    container_port=$(echo $p | sed -e "s/.*://")
    common_port="${common_port} -p $host_port:$container_port"
  done
  echo $common_port
}

#######################
# RENDERING VARIABLE-EMBEDDED YAMLs
#######################
function bonito_l2u {
  echo $1 | tr '[:lower:]' '[:upper:]'
}

# export all BONITO-related shell variables.
function bonito_export {
  for line in `set | grep -E "^BONITO_" | cut -d'=' -f 1`; do
    export $line
  done
  bonito_export_local
}

function bonito_export_local {
  local_params=(user project num_gpu image volume_size pod_name)
  for key in ${local_params[@]}; do
    export BONITO_$(bonito_l2u $key)=$(eval echo '$'$key)
  done
}

function bonito_pod_name {
  echo bonito-$user-$project-pod
}

function bonito_render {
  bonito_export
  template=$1
  if [ ! -e $template ]; then
    bonito_error "file not found: '$template'"
    return 1
  fi
  printf "cat <<++EOS\n`cat $template`\n++EOS\n" | sh
}

function bonito_file_exists {
  # -s can return 1 to existing $1 when $1 is an empty file.
  if [ -s $1 ]; then
    echo 1
  else
    echo 0
  fi
}

function bonito_is_in_file {
  if [ $(bonito_file_exists $proj_dir) -eq 0 ]; then
    echo 0
    return 1
  fi
  if [ $# -ne 2 ]; then
    echo 0
    return 1
  fi
  for word in `cat $1`
  do
    if [ $word == $2 ]; then
      echo 1
      return 0
    fi
  done
  echo 0
  return 0
}

function bonito_confirm_overwrite {
  if [ $# -gt 0 ]; then
    file=$1
  else
    echo "WARNING: bonito_confirm_overwrite function requires at least one argument."
    return 2
  fi

  if [ $(bonito_file_exists $file) -eq 0 ]; then
    return 0
  fi


  echo -n "$file exists. Overwrite? [Y/n]: "
  read ans
  case $ans in
    Y|y|Yes|yes|YES )
      return 0
      ;;
    N|n|No|no|NO )
      return 1
      ;;
    *)
      echo "invalid input."
      bonito_confirm_overwrite $file
      ;;
  esac
}


function bonito_timestamp_sec {
  date "+%Y%m%d-%H%M%S"
}
function bonito_timestamp_msec {
  date "+%Y%m%d-%H%M%S-%3N"
}

function bonito_ip_addresses {
  ifconfig -a | grep inet[^6] | sed 's/.*inet[^6][^0-9]*\([0-9.]*\)[^0-9]*.*/\1/'
}
function bonito_is_registry_server {
  if [ "localhost" == $BONITO_REGIS_SERVER ]; then
    echo 1
    return 0
  fi

  ips=$(bonito_ip_addresses)
  ret=$?
  # fail to get ip addresses
  if [ $ret -eq 1 ]; then
    echo 0
    return 1
  fi

  for ip in $ips; do
    if [ $ip == $BONITO_REGIS_SERVER ]; then
      echo 1
      return 0
    fi
  done
  if [ $(hostname) == $BONITO_REGIS_SERVER ]; then
    echo 1
    return 0
  fi

  echo 0
  return 0
}
