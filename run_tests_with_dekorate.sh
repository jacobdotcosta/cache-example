#!/usr/bin/env bash
source scripts/waitFor.sh

# launch the cache service
oc create -f .openshiftio/cache.yml
if [[ $(waitFor "cache-server" "app") -eq 1 ]] ; then
  echo "Cache server failed to deploy. Aborting"
  exit 1
fi

# 1.- Deploy Cute Name Service
./mvnw -s .github/mvn-settings.xml clean verify -pl cute-name-service -Popenshift -Ddekorate.deploy=true
if [[ $(waitFor "spring-boot-cache-cutename" "app.kubernetes.io/name") -eq 1 ]] ; then
  echo "Cute name service failed to deploy. Aborting"
  exit 1
fi

# 2.- Deploy Greeting Service
./mvnw -s .github/mvn-settings.xml clean verify -pl greeting-service -Popenshift -Ddekorate.deploy=true
if [[ $(waitFor "spring-boot-cache-greeting" "app.kubernetes.io/name") -eq 1 ]] ; then
  echo "Greeting name service failed to deploy. Aborting"
  exit 1
fi

SB_VERSION_SWITCH=""

while getopts v: option
do
    case "${option}"
        in
        v)SB_VERSION_SWITCH="-Dspring-boot.version=${OPTARG}";;
    esac
done

echo "SB_VERSION_SWITCH: ${SB_VERSION_SWITCH}"

# 3.- Run OpenShift Tests
eval "./mvnw -s .github/mvn-settings.xml verify -pl tests -Popenshift-it ${SB_VERSION_SWITCH}"
