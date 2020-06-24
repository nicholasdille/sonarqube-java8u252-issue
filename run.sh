#!/bin/bash

set -o errexit

read -p "Please enter public hostname of SonarQube: " SONARQUBE_DNS_NAME
if test -z "${SONARQUBE_DNS_NAME}"; then
    echo "ERROR: You must specify a public hostname for SonarQube."
    exit 1
fi
export SONARQUBE_DNS_NAME

if ! test -d docker-maven; then
    git clone https://github.com/carlossg/docker-maven.git docker-maven
    cd docker-maven
    git checkout ef95d59
    cp -r openjdk-8-slim openjdk-8u242-slim
    sed -i 's/^FROM openjdk:8-jdk-slim/FROM openjdk:8u242-jdk-slim/' docker-maven/openjdk-8u242-slim/Dockerfile
    cp -r openjdk-8-slim openjdk-8u252-slim
    sed -i 's/^FROM openjdk:8-jdk-slim/FROM openjdk:8u252-jdk-slim/' docker-maven/openjdk-8u252-slim/Dockerfile
    cd ..
fi

docker-compose up -d

while ! curl -s https://${SONARQUBE_DNS_NAME}/batch/index; do
    echo "Waiting for certificate on https://${SONARQUBE_DNS_NAME}/batch/index"
    sleep 5
done

docker-compose exec java8u242 bash -c 'apt-get update && apt-get -y install git'
docker-compose exec --workdir /tmp java8u242 git clone https://github.com/SonarSource/sonar-scanning-examples
docker-compose exec --workdir /tmp/sonar-scanning-examples/sonarqube-scanner-maven/maven-basic java8u242 sed -i 's|<maven.compiler.release>11</maven.compiler.release>||' pom.xml
docker-compose exec --workdir /tmp/sonar-scanning-examples/sonarqube-scanner-maven/maven-basic java8u242 mvn clean verify sonar:sonar -Dsonar.host.url=https://${SONARQUBE_DNS_NAME}

docker-compose exec java8u252 bash -c 'apt-get update && apt-get -y install git'
docker-compose exec --workdir /tmp java8u252 git clone https://github.com/SonarSource/sonar-scanning-examples
docker-compose exec --workdir /tmp/sonar-scanning-examples/sonarqube-scanner-maven/maven-basic java8u252 sed -i 's|<maven.compiler.release>11</maven.compiler.release>||' pom.xml
docker-compose exec --workdir /tmp/sonar-scanning-examples/sonarqube-scanner-maven/maven-basic java8u252 mvn clean verify sonar:sonar -Dsonar.host.url=https://${SONARQUBE_DNS_NAME}
