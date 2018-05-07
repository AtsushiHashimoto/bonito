function bonito_error {
  echo "ERROR: $1"
}

function bonito_print_yml {
  if [ $# -lt 1 ]; then
    bonito_error "bonito_print_yml requres one argument (yml file path)"
    return 0
  fi
  echo $(eval $1)
}

function bonito_image_exists {
  if [ $# -eq 0 ]; then
    tar=$image
  else
    tar=$1
  fi
  if [ `docker images -a | grep $tar`]; then
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
  echo bonito/$user_/$project_:$tag_
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

function bonito_overwrite_test {
  file="bonito.conf"
  bonito_confirm_overwrite $file
  ret=$?
  if [ $ret -gt 0 ]; then
    return 1
  fi
  echo "overwrite $file"
}
