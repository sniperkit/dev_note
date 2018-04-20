#!/usr/bin/env bash

GRADLE_VERSION='4.7'

function install_gradle{
  wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
  mkdir /opt/gradle
  unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip
  ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle
  export PATH=$PATH:/opt/gradle/gradle-${GRADLE_VERSION}/bin
  gradle -v
}

