# Object-based Bayesian SLAM

## Desiderata
   - Bayesian, and in particular implemented in a probabilistic programming language

## Setup
1. Clone the repo
```shell
git clone git@github.com:probcomp/GenSceneDerender.jl.git GenSceneDerender
cd GenSceneDerender
```

2. Pull the pre-built Docker image for GenSceneGraphs from Docker Hub:
```shell
# Login to your Docker Hub account
docker login
# [Docker will interactively ask for your credentials]
# Once signed in, download the Docker image.
docker pull probcomp/genscenegraphs-cpu:latest
```

3. Run the script for the docker container (instantiates the Derendering project, and runs a Jupyter server):
```shell
./scripts/docker_start.sh
```

4. You can exec and attach to a Julia REPL from inside the container by running:
```shell
./scripts/project_julia
```
