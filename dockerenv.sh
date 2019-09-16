#!/usr/bin/env bash

set -eo pipefail

cd "${0%/*}"


from="arm32v7/debian:stretch-slim"
imagename="fnacross/arm32v7:stretch-slim"
hostname="buildenv:arm32v7:stretch-slim"
shortname="arm32v7-stretch-slim"

#from="arm64v8/debian:stretch-slim"
#imagename="fnacross/arm64v8:stretch-slim"
#hostname="buildenv:arm64v8:stretch-slim"

#from="arm32v7/centos:7"
#imagename="fnacross/arm32v7:centos:7"
#hostname="buildenv:arm32v7:centos:7"

replacements="
    s!%%from%%!$from!g;
"

sed "$replacements" Dockerfile.in | docker build --force-rm=true --rm -t "$imagename" -

mkdir -pv $shortname/{prefix,sources}
cp tasks.sh $shortname

# ./dl.sh --extract "$shortname/sources"

docker run --rm -it \
    -v "$(realpath $shortname):/fnacross" \
    -v "$(realpath output):/fnacross/output" \
    -v "/etc/passwd:/etc/passwd:ro" \
    -v "/etc/group:/etc/group:ro" \
    --user $(id -u):$(id -g) \
    -e "TERM=$TERM" \
    -h "$hostname" \
    -w /fnacross \
    "$imagename" \
    "$@"
