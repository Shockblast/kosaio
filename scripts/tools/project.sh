#!/bin/bash
set -e

# Function to create a new project
function create() {
	local project_name=$1

	if [[ -z "$project_name" ]]; then
		echo "Error: Project name is required."
		exit 1
	fi

	# Define the source template directory and the destination project directory
	local template_dir="${KOSAIO_DIR}/basic-project"
	local project_dir="${PROJECTS_DIR}/${project_name}"

	# Check if the template directory exists
	if [ ! -d "${template_dir}" ]; then
		kosaio_echo "Error: basic-project template folder doest exist, check kosaio installation."
		exit 1
	fi

	# Check if the destination project directory already exists
	if [ -d "${project_dir}" ]; then
		kosaio_echo "Error: Destination project directory already exists."
		exit 1
	fi

	echo -e "Creating project '${project_name}' in '${project_dir}' from template... \n"

	# Copy the template directory to the new project path
	cp -a "${template_dir}" "${project_dir}"

	kosaio_echo "Created ${project_dir}, you are ready to go with vscode in you host"
}
