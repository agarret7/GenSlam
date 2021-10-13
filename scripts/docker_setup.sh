#!/bin/bash

/julia_projects/MyProject/deps/GenSceneGraphs.jl/container_scripts/myproject_julia \
    --project=/julia_projects/MyProject -e "import Pkg; Pkg.instantiate()"

cd /julia_projects/MyProject

pip3 install -r requirements.txt

cd model
jupyter notebook \
        --ip='0.0.0.0' \
        --port=8080 \
        --no-browser \
        --NotebookApp.token= \
        --allow-root \
        --NotebookApp.iopub_data_rate_limit=-1
