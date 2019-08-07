set -e
cd /${project_root_dir}
git clone ${terraform_project_url}
cd ${project_dir}
git checkout ${branch}