#!/bin/bash

# TODO move this stuff to a Dockerfile extending from probcomp-cpu:latest

PROJECT_ROOT_PATH=/julia_projects/MyProject
GSG_ROOT_PATH=$PROJECT_ROOT_PATH/deps/GenSceneGraphs.jl

# manually update registries to fix shenanigans
apt update -y && apt install -y git
mkdir -p /root/.julia/registries
cd /root/.julia/registries
rm -rf General
git clone https://github.com/JuliaRegistries/General.git

echo '## Looks like IJulia needs to be installed on the system Julia' \
     '## as well, or else Jupyter will crash-loop' > /dev/null
julia -e 'import Pkg; Pkg.add("IJulia")'
echo '## Activate nvm so that the $PATH seen by `install_jupyter_kernel`' \
     '## (which gets baked into the resulting kernel definition)' \
     '## includes the nvm bin dir' > /dev/null
. $NVM_DIR/nvm.sh
$GSG_ROOT_PATH/container_scripts/install_jupyter_kernel
julia --project=$PROJECT_ROOT_PATH \
      -e 'import Pkg; Pkg.update(); Pkg.add("PoseComposition"); Pkg.instantiate()'
cd $PROJECT_ROOT_PATH
pip3 install -r requirements.txt
jupyter notebook \
        --ip='0.0.0.0' \
        --port=8080 \
        --no-browser \
        --NotebookApp.token= \
        --allow-root \
        --NotebookApp.iopub_data_rate_limit=-1
