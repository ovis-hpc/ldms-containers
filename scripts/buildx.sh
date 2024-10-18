#!/bin/bash

# work from the top dir
D=$(dirname $0)
cd ${D}/..

docker buildx bake "$@"
