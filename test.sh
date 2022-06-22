#!/bin/bash

set -o errexit

read -p "Please enter public hostname of SonarQube: " SONARQUBE_DNS_NAME
if test -z "${SONARQUBE_DNS_NAME}"; then
    echo "ERROR: You must specify a public hostname for SonarQube."
    exit 1
fi
export SONARQUBE_DNS_NAME

VERSIONS="8 8u252 8u242"

if ! test -d docker-maven; then
    git clone -q --depth 1 https://github.com/carlossg/docker-maven.git docker-maven
    cd docker-maven

    for VERSION in ${VERSIONS}; do
        cp -r openjdk-8-slim openjdk-${VERSION}-slim
        sed -i "s/^FROM openjdk:8-jdk-slim/FROM openjdk:${VERSION}-jdk-slim/" openjdk-${VERSION}-slim/Dockerfile
    done

    cd ..
fi

docker-compose build

while ! curl -s https://${SONARQUBE_DNS_NAME}/batch/index; do
    echo "Checking connection to https://${SONARQUBE_DNS_NAME}/batch/index"
    sleep 5
done

for VERSION in ${VERSIONS}; do
    echo "###################################################"
    echo "### Testing java${VERSION}"
    echo "###################################################"

    docker run --name java${VERSION} -d --entrypoint sh maven:openjdk-${VERSION}-slim -c 'while true; do sleep 10; done'

    docker exec --interactive java${VERSION} bash -c 'apt-get update && apt-get -y install git'
    docker exec --interactive --workdir /tmp java${VERSION} \
        bash -c 'test -d /tmp/sonar-scanning-examples || git clone https://github.com/SonarSource/sonar-scanning-examples'
    docker exec --interactive --workdir /tmp/sonar-scanning-examples/sonarqube-scanner-maven/maven-basic java${VERSION} \
        sed -i 's|<maven.compiler.release>11</maven.compiler.release>||' pom.xml
    docker exec --interactive --workdir /tmp/sonar-scanning-examples/sonarqube-scanner-maven/maven-basic java${VERSION} \
        sed -i 's|3.7.0.1746|3.5.0.1254|' pom.xml
    docker exec --interactive --workdir /tmp/sonar-scanning-examples/sonarqube-scanner-maven/maven-basic java${VERSION} \
        mvn clean verify sonar:sonar -Dsonar.host.url=https://${SONARQUBE_DNS_NAME}

    docker rm -f java${VERSION}
done