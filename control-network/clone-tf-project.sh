mkdir /project
cd /project
git clone ${terraform_project_url}
mv ${project_dir}/network/backend.tf.bak ${project_dir}/network/backend.tf
mv ${project_dir}/backend.tf.bak ${project_dir}/backend.tf