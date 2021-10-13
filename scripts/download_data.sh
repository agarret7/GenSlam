#!/bin/bash

# make meshes directory
mkdir -p meshes

# download YCB meshes (from http://ycb-benchmarks.s3-website-us-east-1.amazonaws.com/)
URL_PREFIX=http://ycb-benchmarks.s3-website-us-east-1.amazonaws.com/data/berkeley
for mesh in 003_cracker_box 006_mustard_bottle; do
    wget $URL_PREFIX/$mesh/${mesh}_berkeley_meshes.tgz -O meshes/$mesh.tgz
    tar xvf meshes/$mesh.tgz -C meshes
    rm meshes/$mesh.tgz
done

echo "DONE"
