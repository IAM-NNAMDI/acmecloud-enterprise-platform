#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# AcmeCloud Enterprise Platform
# AWS Lab Restore
#
# Restore order:
#   1. NAT Gateway
#   2. Amazon EKS
#   3. kubeconfig
#   4. AWS Load Balancer Controller
#   5. Kubernetes workloads
#   6. Ingress / ALB
#   7. Validation
# ============================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"
EKS_DIR="${REPO_ROOT}/kubernetes/eks"

REGION="us-east-1"
CLUSTER_NAME="acmecloud-production-eks"
NAMESPACE="acmecloud"
LBC_CHART_VERSION="3.5.0"

echo "============================================================"
echo " AcmeCloud AWS Lab Restore"
echo "============================================================"
echo

cd "${TF_DIR}"

# ------------------------------------------------------------
# 1. Restore NAT Gateway first
# ------------------------------------------------------------

echo "=== STEP 1: ENABLE NAT GATEWAY ==="

if grep -q '^enable_nat_gateway' terraform.tfvars; then
    sed -i \
        's/^enable_nat_gateway *= *.*/enable_nat_gateway = true/' \
        terraform.tfvars
else
    printf '\nenable_nat_gateway = true\n' >> terraform.tfvars
fi

# Keep EKS disabled during NAT restoration.
if grep -q '^enable_eks' terraform.tfvars; then
    sed -i 's/^enable_eks *= *.*/enable_eks = false/' terraform.tfvars
else
    printf '\nenable_eks = false\n' >> terraform.tfvars
fi

grep -E '^enable_(eks|nat_gateway)' terraform.tfvars

terraform apply -auto-approve

echo
echo "NAT Gateway restoration complete."

echo

# ------------------------------------------------------------
# 2. Restore EKS
# ------------------------------------------------------------

echo "=== STEP 2: ENABLE AMAZON EKS ==="

sed -i 's/^enable_eks *= *.*/enable_eks = true/' terraform.tfvars

grep '^enable_eks' terraform.tfvars

terraform apply -auto-approve

echo

# ------------------------------------------------------------
# 3. Configure kubectl
# ------------------------------------------------------------

echo "=== STEP 3: CONFIGURE KUBECTL ==="

aws eks update-kubeconfig \
    --region "${REGION}" \
    --name "${CLUSTER_NAME}"

echo
echo "Waiting for EKS nodes..."

kubectl wait \
    --for=condition=Ready \
    nodes \
    --all \
    --timeout=10m

kubectl get nodes -o wide

echo

# ------------------------------------------------------------
# 4. Restore AWS Load Balancer Controller
# ------------------------------------------------------------

echo "=== STEP 4: AWS LOAD BALANCER CONTROLLER ==="

LBC_ROLE_ARN="$(
    terraform output -raw eks_load_balancer_controller_role_arn
)"

VPC_ID="$(
    terraform output -raw vpc_id
)"

helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo update

helm upgrade --install aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    --version "${LBC_CHART_VERSION}" \
    --namespace kube-system \
    --set clusterName="${CLUSTER_NAME}" \
    --set serviceAccount.create=true \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${LBC_ROLE_ARN}" \
    --set region="${REGION}" \
    --set vpcId="${VPC_ID}" \
    --wait \
    --timeout 10m

kubectl rollout status \
    deployment/aws-load-balancer-controller \
    -n kube-system \
    --timeout=5m

echo

# ------------------------------------------------------------
# 5. Restore Kubernetes workloads
# ------------------------------------------------------------

echo "=== STEP 5: DEPLOY ACMECLOUD WORKLOADS ==="

kubectl apply -f "${EKS_DIR}/namespace.yaml"

kubectl apply -f "${EKS_DIR}/app/"
kubectl apply -f "${EKS_DIR}/web/"

echo
echo "Waiting for application deployment..."

kubectl rollout status \
    deployment/acmecloud-app \
    -n "${NAMESPACE}" \
    --timeout=10m

echo
echo "Waiting for web deployment..."

kubectl rollout status \
    deployment/acmecloud-web \
    -n "${NAMESPACE}" \
    --timeout=10m

echo

# ------------------------------------------------------------
# 6. Restore Ingress / ALB
# ------------------------------------------------------------

echo "=== STEP 6: CREATE INGRESS / ALB ==="

kubectl apply -f "${EKS_DIR}/ingress.yaml"

echo
echo "Waiting for ALB address..."

ALB_DNS=""

for i in {1..60}; do

    ALB_DNS="$(
        kubectl get ingress acmecloud-web \
            -n "${NAMESPACE}" \
            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
            2>/dev/null || true
    )"

    if [[ -n "${ALB_DNS}" ]]; then
        break
    fi

    sleep 10
done

if [[ -z "${ALB_DNS}" ]]; then
    echo "ERROR: ALB was not provisioned within 10 minutes."
    kubectl describe ingress acmecloud-web -n "${NAMESPACE}"
    exit 1
fi

echo "ALB DNS: ${ALB_DNS}"

echo

# ------------------------------------------------------------
# 7. HTTP validation
# ------------------------------------------------------------

echo "=== STEP 7: VALIDATE ACMECLOUD ==="

echo "Waiting for ALB targets to become healthy..."

ROOT_CODE=""
APP_CODE=""

for i in {1..30}; do

    ROOT_CODE="$(
        curl -s -o /dev/null \
            -w '%{http_code}' \
            "http://${ALB_DNS}/" || true
    )"

    APP_CODE="$(
        curl -s -o /dev/null \
            -w '%{http_code}' \
            "http://${ALB_DNS}/app/" || true
    )"

    echo "Attempt ${i}: /=${ROOT_CODE} /app/=${APP_CODE}"

    if [[ "${ROOT_CODE}" == "200" && "${APP_CODE}" == "200" ]]; then
        break
    fi

    sleep 10
done

if [[ "${ROOT_CODE}" != "200" || "${APP_CODE}" != "200" ]]; then
    echo "ERROR: AcmeCloud HTTP validation failed."
    exit 1
fi

echo
echo "Root endpoint:     HTTP ${ROOT_CODE}"
echo "Application path:  HTTP ${APP_CODE}"

echo
# ------------------------------------------------------------
# 8. Restore Prometheus / Grafana monitoring
# ------------------------------------------------------------

echo "=== STEP 8: RESTORE MONITORING STACK ==="

MONITORING_DIR="${PROJECT_ROOT}/monitoring"
MONITORING_NAMESPACE="monitoring"
MONITORING_RELEASE="acmecloud-monitoring"
PROMETHEUS_CHART_VERSION="91.9.0"

echo
echo "Adding Prometheus Community Helm repository..."

helm repo add prometheus-community \
    https://prometheus-community.github.io/helm-charts \
    --force-update

helm repo update

echo
echo "Installing kube-prometheus-stack ${PROMETHEUS_CHART_VERSION}..."

helm upgrade --install "${MONITORING_RELEASE}" \
    prometheus-community/kube-prometheus-stack \
    --version "${PROMETHEUS_CHART_VERSION}" \
    --namespace "${MONITORING_NAMESPACE}" \
    --create-namespace \
    -f "${MONITORING_DIR}/values.yaml" \
    --wait \
    --timeout 10m

echo
echo "Applying AcmeCloud Prometheus alert rules..."

kubectl apply \
    -f "${MONITORING_DIR}/alerts/acmecloud-alerts.yaml"

echo
echo "Provisioning AcmeCloud Grafana dashboard..."

kubectl create configmap acmecloud-grafana-dashboard \
    --namespace "${MONITORING_NAMESPACE}" \
    --from-file=acmecloud-overview.json="${MONITORING_DIR}/dashboards/acmecloud-overview.json" \
    --dry-run=client \
    -o yaml \
    | kubectl label \
        --local \
        -f - \
        grafana_dashboard=1 \
        -o yaml \
    | kubectl apply -f -

echo
echo "Waiting for monitoring workloads..."

kubectl wait \
    --for=condition=Ready \
    pods \
    --all \
    -n "${MONITORING_NAMESPACE}" \
    --timeout=10m

echo
echo "=== MONITORING STATUS ==="

helm list -n "${MONITORING_NAMESPACE}"

echo
kubectl get pods \
    -n "${MONITORING_NAMESPACE}" \
    -o wide

echo
kubectl get prometheus,alertmanager \
    -n "${MONITORING_NAMESPACE}"

echo
echo "Custom PrometheusRule:"
kubectl get prometheusrule \
    acmecloud-platform-alerts \
    -n "${MONITORING_NAMESPACE}"

echo
echo "Custom Grafana dashboard:"
kubectl get configmap \
    acmecloud-grafana-dashboard \
    -n "${MONITORING_NAMESPACE}" \
    --show-labels

echo

# ------------------------------------------------------------
# 9. Final environment status
# ------------------------------------------------------------

echo "=== STEP 9: FINAL ENVIRONMENT STATUS ==="

kubectl get nodes

echo
kubectl get pods -n "${NAMESPACE}" -o wide

echo
kubectl get svc -n "${NAMESPACE}"

echo
kubectl get ingress -n "${NAMESPACE}"

echo
echo "Monitoring namespace:"
kubectl get pods -n "${MONITORING_NAMESPACE}"

echo
echo "============================================================"
echo " AcmeCloud AWS Lab Restore Complete"
echo "============================================================"
echo
echo "Application URL:"
echo "http://${ALB_DNS}"
echo
echo "Monitoring:"
echo "Prometheus + Grafana + Alertmanager restored successfully."
echo
echo "Grafana access:"
echo "kubectl -n monitoring port-forward svc/acmecloud-monitoring-grafana 3000:80"
