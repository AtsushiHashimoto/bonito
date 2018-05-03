function bonito_print_basic_options {
  cat <<EOF
    --user            direct project user name. (Default: $USER)
    --project         direct project name. (Default: default)
    --version         print $(basename ${0}) version
    --help, -h        print this
    --verbose,-v      print debug messages
    --debug           set -x
EOF
}

function help_bonito_basic {
  cat <<EOF
$(basename ${0}) $1 is a command $2

Usage:
    $(basename ${0}) info [<options>]

Options:
$(bonito_print_basic_options)
$3
EOF
}

function bonito_file_exists {
  # -s can return 1 to existing $1 when $1 is an empty file.
  if [ -s $1 ]; then
    echo 1
  else
    echo 0
  fi
}
function bonito_project_yaml {
  proj_dir=$BONITO_DIR/projects
  if [ $(bonito_file_exists $proj_dir) -eq 0 ]; then
    mkdir -p $proj_dir
  fi
  echo $proj_dir/$user.$project.yaml
}

function has_base_project {
  tpl=$BONITO_TPL_DIR/default.$project.yaml
  echo $(bonito_file_exists $tpl)
}

function bonito_base_template {
  if [ $(has_base_project) -eq 1 ]; then
    echo $BONITO_TPL_DIR/default.$project.yaml
  else
    echo $BONITO_TPL_YAML
  fi
}

function bonito_render_project_yaml {
  tpl=$(bonito_base_template)
  bonito_render $tpl
}


function print_options_bonito_create {
  cat <<EOF
    --num_gpu,-g       direct number of gpus used in this project.
                      (Default: 1)
    --base_image,-b    direct base image of this project.
                      (Default: $BONITO_USER.$BONITO_PROJECT)
    --volume_size,-s   direct user's home volume limit
EOF
# default values for num_gpu,image,volume_size are defined in $BONITO_DIR/bin/bonito}
}

function help_bonito_create {
  help_bonito_basic create "create a new project" "$(print_options_bonito_create)"
}

function bonito_create {
  yaml=$(bonito_project_yaml)
  if [ $(bonito_file_exists $yaml) -eq 1 ]; then
    bonito_error "The project is already exists. Just run the project."
    return 1
  fi
  # tag base image
  docker tag $base_image $image
  bonito_render_project_yaml > $yaml
  kubectl apply -f $yaml
  bonito_push
}

function help_bonito_push {
  help_bonito_basic push "push the project image to registry" ""
}
function bonito_push {
  # docker commit
  docker tag $image $(bonito_image $(date +%Y%m%d-%H%M%S))
  docker commit $image
  docker push $image
}

function help_bonito_run {
  help_bonito_basic run "start/attach to the project pod." ""
}

function bonito_run {
  yaml=$(bonito_project_yaml)
  if [ $(bonito_file_exists $yaml) -eq 0 ]; then
    bonito_error "Unknown project: $user.$project\nTo create a new project, use create command. ex.) bonito create --user $user --project $project"
    return 1
  fi
  kubectl apply -f $yaml
}

function help_bonito_shutdown {
  help_bonito_basic shutdown "shutdown running pod of the project." ""
}

function bonito_shutdown {
  yaml=$(bonito_project_yaml)
  if [ $(bonito_file_exists $yaml) -eq 0 ]; then
    bonito_error "Unknown project: $user.$project"
    return 1
  fi
  kubectl delete -f $yaml
}

function help_bonito_info {
  help_bonito_basic info "show project information." ""
}

function bonito_info {
  echo user: $user
  echo project name: $project
  echo yaml: $(bonito_project_yaml)
  if [ $is_verbose -eq 1 ]; then
    cat $(bonito_project_yaml)
  fi
  # renderingして今のテンプレートとずれているかどうかをチェックする機能があった方が良い
  echo base yaml template: $(bonito_base_template)
  if [ $is_verbose -eq 1 ]; then
    cat $(bonito_base_template)
  fi
  echo persistent volumes:
}
