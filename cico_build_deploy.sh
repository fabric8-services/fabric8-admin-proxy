#!/bin/bash

# Output command before executing
set -x

# Exit on error
set -e

REGISTRY="push.registry.devshift.net"

function tag_push() {
  local tag=$1
  docker tag f8adminproxy-deploy $tag
  docker push $tag
}

# Source environment variables of the jenkins slave
# that might interest this worker.
function load_jenkins_vars() {
  if [ -e "jenkins-env" ]; then
    cat jenkins-env \
      | grep -E "(DEVSHIFT_TAG_LEN|DEVSHIFT_USERNAME|DEVSHIFT_PASSWORD|JENKINS_URL|GIT_BRANCH|GIT_COMMIT|BUILD_NUMBER|ghprbSourceBranch|ghprbActualCommit|BUILD_URL|ghprbPullId)=" \
      | sed 's/^/export /g' \
      > ~/.jenkins-env
    source ~/.jenkins-env
  fi
}

function login() {
  if [ -n "${DEVSHIFT_USERNAME}" -a -n "${DEVSHIFT_PASSWORD}" ]; then
    docker login -u ${DEVSHIFT_USERNAME} -p ${DEVSHIFT_PASSWORD} ${REGISTRY}
  else
    echo "Could not login, missing credentials for the registry"
  fi
}

 # We need to disable selinux for now, XXX
/usr/sbin/setenforce 0 || :

# Get all the deps in
yum -y install \
   docker \
   make \
   git \
   curl

service docker start

load_jenkins_vars

TAG=$(echo $GIT_COMMIT | cut -c1-${DEVSHIFT_TAG_LEN})

login

if [ "$TARGET" = "rhel" ]; then
  docker build -t f8adminproxy-deploy -f "Dockerfile.rhel" .

  tag_push ${REGISTRY}/osio-prod/fabric8-services/fabric8-admin-proxy:$TAG
  tag_push ${REGISTRY}/osio-prod/fabric8-services/fabric8-admin-proxy:latest
else
  docker build -t f8adminproxy-deploy -f "Dockerfile" .

  tag_push ${REGISTRY}/fabric8-services/fabric8-admin-proxy:$TAG
  tag_push ${REGISTRY}/fabric8-services/fabric8-admin-proxy:latest
fi

echo 'CICO: Image pushed, ready to update deployed app'
