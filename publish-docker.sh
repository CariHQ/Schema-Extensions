#!/usr/bin/env bash

set -e

docker login
VERSION=`cat ./.dockerHubVersion`
echo "Next Version? (current: "${VERSION}")"
read nversion
echo "Let's build new image with tag: idchain/schema-extensions:"${nversion}
docker build . -t idchain/schema-extensions:${nversion}
docker push idchain/schema-extensions:${nversion}
echo ${nversion} > ./.dockerHubVersion

git add ./.dockerHubVersion
msg=`echo New schema-extensions image release version: ${nversion}`
echo ${msg}
git commit -m "$msg"
git push
