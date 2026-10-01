#!/bin/bash
dnf update -y
dnf install -y git vim unzip wget curl
hostnamectl set-hostname bastion