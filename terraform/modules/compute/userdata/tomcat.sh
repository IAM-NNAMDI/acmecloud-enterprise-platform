#!/bin/bash

dnf update -y
dnf install -y java-17-amazon-corretto

useradd tomcat || true

mkdir -p /opt/tomcat

hostnamectl set-hostname tomcat