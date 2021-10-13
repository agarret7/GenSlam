PROJECT_DIR=$(dirname $(dirname $(readlink -f $0)))

docker run --entrypoint=/julia_projects/MyProject/scripts/docker_setup.sh \
	     --name="genscenegraphs_user" -v "${PROJECT_DIR}:/julia_projects/MyProject" \
	     -p "8080:8080" -td probcomp/genscenegraphs-cpu:latest
