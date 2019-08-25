#!/bin/sh

if [ -z "${INPUT_NAME}" ]; then
  echo "Unable to find the repository name. Did you set with.name?"
  exit 1
fi

if [ -z "${INPUT_USERNAME}" ]; then
  echo "Unable to find the username. Did you set with.username?"
  exit 1
fi

if [ -z "${INPUT_PASSWORD}" ]; then
  echo "Unable to find the password. Did you set with.password?"
  exit 1
fi

# If a PR, then use the merging branch
[[ "$GITHUB_HEAD_REF" ]] && BRANCH="${GITHUB_HEAD_REF}" || BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g")

if [ "${BRANCH}" == "master" ]; then
  BRANCH="latest"
fi;

# if contains /refs/tags/
if [ $(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g") != ${GITHUB_REF} ]; then
  BRANCH="latest"
fi;

DOCKERNAME="${INPUT_NAME}:${BRANCH}"
CUSTOMDOCKERFILE=""

if [ ! -z "${INPUT_DOCKERFILE}" ]; then
  CUSTOMDOCKERFILE="-f ${INPUT_DOCKERFILE}"
fi

docker login -u ${INPUT_USERNAME} -p ${INPUT_PASSWORD} ${INPUT_REGISTRY}

# go ahead and build and create both tags. Doesn't cost anything
SHA_DOCKER_NAME="${INPUT_NAME}:${GITHUB_SHA}"
docker build $CUSTOMDOCKERFILE -t ${DOCKERNAME} -t ${SHA_DOCKER_NAME} .

# push the non-SHA version if this is not a PR
if [ -z "$GITHUB_HEAD_REF" ]; then
  docker push ${DOCKERNAME}
fi

# if either snapshot or a PR, then push the SHA version
if [ "${INPUT_SNAPSHOT}" == "true" ] || ["$GITHUB_HEAD_REF" ]; then
  docker push ${SHA_DOCKER_NAME}
fi

docker logout
