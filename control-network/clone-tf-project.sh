mkdir /project
cd /project
git clone ${terraform_project_url}
mv ${project_dir}/network/backend.tf.bak ${project_dir}/network/backend.tf
mv ${project_dir}/backend.tf.bak ${project_dir}/backend.tf
mv ${project_dir}/remote_state_local.tf ${project_dir}/remote_state_local.tf.bak
mv ${project_dir}/remote_state_backend.tf.bak ${project_dir}/remote_state_backend.tf