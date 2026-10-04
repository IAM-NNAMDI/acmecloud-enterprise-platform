# AcmeCloud CI/CD Pipeline

## Overview

The AcmeCloud Enterprise Platform uses GitHub Actions to implement a secure CI/CD pipeline for validating, scanning, building, publishing, and deploying the platform.

The pipeline integrates:

- GitHub Actions
- Docker
- Trivy
- GitHub OpenID Connect (OIDC)
- AWS IAM
- Amazon Elastic Container Registry (ECR)
- Amazon Elastic Kubernetes Service (EKS)
- Kubernetes rollout verification and rollback controls

Long-lived AWS access keys are not stored in GitHub. GitHub Actions authenticates to AWS by assuming a dedicated IAM role through GitHub OIDC.

## Pipeline Flow

A push to the `main` branch triggers the CI/CD workflow.

The pipeline performs:

1. Repository validation.
2. Docker build validation.
3. Kubernetes manifest validation.
4. Trivy HIGH and CRITICAL vulnerability scanning.
5. GitHub-to-AWS OIDC authentication.
6. Application and web container builds.
7. Commit-SHA image tagging.
8. Publishing images to private Amazon ECR repositories.
9. Authentication to Amazon EKS.
10. Deployment of the application and web workloads.
11. Kubernetes rollout verification.
12. Deployed-image verification.
13. Rollback if rollout verification fails.

## Workflow

The workflow is stored at:

    .github/workflows/ci.yml

The main delivery path is:

    Git Push
       |
       v
    GitHub Actions
       |
       +-- Repository validation
       +-- Docker validation
       +-- Kubernetes validation
       +-- Trivy security scan
       |
       v
    GitHub OIDC
       |
       v
    AWS IAM
       |
       +--> Amazon ECR
       |
       +--> Amazon EKS

## Container Image Versioning

Production images use the first 12 characters of the Git commit SHA instead of a mutable `latest` tag.

Example validated release:

    acmecloud-app:f5b98673f344
    acmecloud-web:f5b98673f344

This provides traceability between the Git commit, GitHub Actions run, ECR image, and EKS deployment.

The Amazon ECR repositories use immutable image tags.

## AWS Authentication

GitHub Actions authenticates to AWS using GitHub OIDC and assumes the dedicated IAM role:

    acmecloud-production-github-actions

No permanent AWS access key or secret access key is required by the pipeline.

The OIDC trust relationship is restricted to the AcmeCloud GitHub repository identity used by the main-branch workflow.

## Amazon ECR

The pipeline publishes images to the private repositories:

    acmecloud-app
    acmecloud-web

Each successful release receives its Git commit SHA tag before being pushed to ECR.

## Amazon EKS Deployment

The CD job manages:

    deployment/acmecloud-app
    deployment/acmecloud-web

inside the Kubernetes namespace:

    acmecloud

The GitHub Actions IAM principal is authorized through an Amazon EKS access entry.

Application deployment access is namespace-scoped to `acmecloud`.

Namespace creation remains a platform bootstrap responsibility and is intentionally not performed by the application deployment job.

## Security Controls

The CI/CD implementation includes:

- GitHub OIDC instead of long-lived AWS credentials
- Dedicated AWS IAM role for GitHub Actions
- Restricted OIDC trust relationship
- Namespace-scoped EKS deployment authorization
- Private ECR repositories
- Immutable ECR image tags
- Commit-SHA release versioning
- Trivy container vulnerability scanning
- Kubernetes rollout verification
- Rollback controls
- Main-branch deployment restriction

## Deployment Verification

After deployment, GitHub Actions waits for both Kubernetes deployments to complete their rollouts.

The workflow verifies:

- Application rollout status
- Web rollout status
- Running deployments
- Running pods
- Deployed ECR image references
- Release SHA

## Rollback Controls

If rollout verification fails, the workflow contains conditional rollback logic using `kubectl rollout undo`.

Both the application and web deployments are rolled back together so the platform is not intentionally left running mixed releases.

The rollback procedure then verifies that both restored deployments successfully roll out.

## Rollback Test

The Kubernetes rollback mechanism was tested with deliberately invalid ECR image tags.

The replacement pods entered:

    ErrImagePull

while the existing healthy replicas remained available.

The application and web deployments were then rolled back successfully to:

    f5b98673f344

Final state:

    acmecloud-app   2/2 Ready
    acmecloud-web   2/2 Ready

This directly validated the Kubernetes failure and rollback procedure.

The GitHub Actions conditional rollback branch itself has not been deliberately triggered by pushing a broken production release to `main`.

## Separation of Responsibilities

Terraform manages infrastructure including:

- VPC networking
- IAM
- Amazon EKS
- Managed node groups
- GitHub OIDC integration
- EKS access authorization

GitHub Actions manages application delivery including:

- CI validation
- Container builds
- Security scanning
- ECR publishing
- Kubernetes workload deployment
- Rollout verification
- Rollback controls

This separation prevents the application deployment pipeline from receiving unnecessary infrastructure-administration permissions.
