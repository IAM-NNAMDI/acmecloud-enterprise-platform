# AcmeCloud Monitoring

This directory contains the monitoring configuration for the
AcmeCloud Enterprise Platform.

## Monitoring Stack

The platform uses:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter

The monitoring stack is deployed to Amazon EKS using Helm and the
kube-prometheus-stack chart.

## Namespace

Monitoring components are deployed into the `monitoring` namespace.

## Purpose

The monitoring stack provides visibility into:

- Kubernetes node health
- CPU and memory utilization
- Pod health and availability
- Deployment replica status
- Container restarts
- AcmeCloud web and application workloads
- Kubernetes cluster health

Grafana uses Prometheus as its primary metrics data source.

## Architecture

The monitoring stack runs inside the Amazon EKS cluster and provides
observability across the infrastructure, Kubernetes, and application
layers.

Prometheus collects metrics from the EKS worker nodes, Kubernetes
components, and AcmeCloud workloads. Grafana provides visualization,
while Alertmanager handles alerts generated from Prometheus rules.

The detailed architecture, metrics flow, access model, and storage
strategy are documented here:

[AcmeCloud Monitoring Architecture](architecture/README.md)
