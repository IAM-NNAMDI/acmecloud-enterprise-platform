#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# AcmeCloud Enterprise Platform
# AWS Lab Shutdown
#
# Shutdown order:
#   1. Kubernetes Ingress / ALB
#   2. Amazon EKS
#   3. NAT Gateway
#   4. Verification
#
# Persistent infrastructure such as the VPC, subnets,
# security groups, ECR images and Terraform state is preserved.
# ============================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"
EKS_MANIFEST="${REPO_ROOT}/kubernetes/eks/ingress.yaml"

REGION="us-east-1"
CLUSTER_NAME="acmecloud-production-eks"
NAMESPACE="acmecloud"

echo "============================================================"
echo " AcmeCloud AWS Lab Shutdown"
echo "============================================================"
echo

cd "${TF_DIR}"

# ------------------------------------------------------------
# 1. Remove Kubernetes Ingress first
# ------------------------------------------------------------

echo "=== STEP 1: REMOVE KUBERNETES INGRESS / ALB ==="

if aws eks describe-cluster \
    --name "${CLUSTER_NAME}" \
    --region "${REGION}" \
    >/dev/null 2>&1; then

    echo "EKS cluster exists."

    aws eks update-kubeconfig \
        --region "${REGION}" \
        --name "${CLUSTER_NAME}" \
        >/dev/null

    if kubectl get ingress acmecloud-web \
        -n "${NAMESPACE}" >/dev/null 2>&1; then

        echo "Deleting AcmeCloud ingress..."

        kubectl delete \
            -f "${EKS_MANIFEST}" \
            --ignore-not-found=true

        echo "Waiting for ingress deletion..."

        for i in {1..30}; do
            if ! kubectl get ingress acmecloud-web \
                -n "${NAMESPACE}" >/dev/null 2>&1; then
                break
            fi

            sleep 10
        done
    else
        echo "AcmeCloud ingress is already absent."
    fi

    echo "Waiting for Kubernetes ALB cleanup..."

    for i in {1..30}; do
        ALB_COUNT="$(
            aws elbv2 describe-load-balancers \
                --region "${REGION}" \
                --query "length(LoadBalancers[?contains(LoadBalancerName, 'k8s-acmeclou')])" \
                --output text
        )"

        if [[ "${ALB_COUNT}" == "0" ]]; then
            echo "Kubernetes ALB cleanup complete."
            break
        fi

        sleep 10
    done

else
    echo "EKS cluster is already absent."
fi

echo

# ------------------------------------------------------------
# 2. Disable EKS
# ------------------------------------------------------------

echo "=== STEP 2: DISABLE AMAZON EKS ==="

if grep -q '^enable_eks' terraform.tfvars; then
    sed -i 's/^enable_eks *= *.*/enable_eks = false/' terraform.tfvars
else
    printf '\nenable_eks = false\n' >> terraform.tfvars
fi

grep '^enable_eks' terraform.tfvars

echo
echo "Applying EKS shutdown..."

# EKS occasionally returns ResourceInUseException immediately
# after its managed node group disappears. Retry Terraform so
# AWS has time to finish backend cleanup.

MAX_EKS_ATTEMPTS=3

for attempt in $(seq 1 "${MAX_EKS_ATTEMPTS}"); do

    echo "Terraform EKS shutdown attempt ${attempt}/${MAX_EKS_ATTEMPTS}"

    if terraform apply -auto-approve; then
        break
    fi

    if [[ "${attempt}" -eq "${MAX_EKS_ATTEMPTS}" ]]; then
        echo "ERROR: EKS shutdown failed after ${MAX_EKS_ATTEMPTS} attempts."
        exit 1
    fi

    echo "Waiting 30 seconds before retry..."
    sleep 30
done

echo

# ------------------------------------------------------------
# 3. Disable NAT Gateway
# ------------------------------------------------------------

echo "=== STEP 3: DISABLE NAT GATEWAY ==="

if grep -q '^enable_nat_gateway' terraform.tfvars; then
    sed -i \
        's/^enable_nat_gateway *= *.*/enable_nat_gateway = false/' \
        terraform.tfvars
else
    printf '\nenable_nat_gateway = false\n' >> terraform.tfvars
fi

grep '^enable_nat_gateway' terraform.tfvars

echo
echo "Applying NAT Gateway shutdown..."

terraform apply -auto-approve

echo

# ------------------------------------------------------------
# 4. Verification
# ------------------------------------------------------------

echo "=== STEP 4: FINAL VERIFICATION ==="

echo
echo "--- Cost-control settings ---"

grep -E '^enable_(eks|nat_gateway)' terraform.tfvars

echo
echo "--- Terraform EKS state ---"

terraform state list | grep '^module\.eks' \
    || echo "No EKS resources in Terraform state."

echo
echo "--- AWS EKS cluster ---"

if aws eks describe-cluster \
    --name "${CLUSTER_NAME}" \
    --region "${REGION}" \
    >/dev/null 2>&1; then

    echo "WARNING: EKS cluster still exists."
else
    echo "EKS cluster is absent."
fi

echo
echo "--- Active NAT Gateways ---"

aws ec2 describe-nat-gateways \
    --region "${REGION}" \
    --filter Name=vpc-id,Values=vpc-0a217bd92a4f52de7 \
    --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State]' \
    --output table

echo
echo "--- Kubernetes ALBs ---"

aws elbv2 describe-load-balancers \
    --region "${REGION}" \
    --query \
    "LoadBalancers[?contains(LoadBalancerName, 'k8s-acmeclou')].[LoadBalancerName,State.Code]" \
    --output table

echo
echo "--- Terraform consistency ---"

terraform plan -detailed-exitcode >/tmp/acmecloud-shutdown-plan.txt || PLAN_RC=$?
PLAN_RC="${PLAN_RC:-0}"

case "${PLAN_RC}" in
    0)
        echo "Terraform: No changes."
        ;;
    2)
        echo "WARNING: Terraform still detects changes."
        cat /tmp/acmecloud-shutdown-plan.txt
        exit 2
        ;;
    *)
        echo "ERROR: Terraform plan failed."
        cat /tmp/acmecloud-shutdown-plan.txt
        exit 1
        ;;
esac

echo
echo "============================================================"
echo " AcmeCloud AWS Lab Shutdown Complete"
echo "============================================================"
