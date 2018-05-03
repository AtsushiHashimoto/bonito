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

function bonito_image {
  echo $BONITO_MASTER_IP:$BONITO_REGIS_PORT/$user.$project:$1
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
  local_params=(user project num_gpu image volume_size)
  for key in ${local_params[@]}; do
    export BONITO_$(bonito_l2u $key)=$(eval echo '$'$key)
  done
}

function bonito_render {
  bonito_export
  template=$1
  output_file=$2
  printf "cat <<++EOS\n`cat $template`\n++EOS\n" | sh
  #python3 ${BONITO_DIR}/template_render.py $template --user "$user" --project "$project" --num_gpu "$num_gpu" > $output_file
}
