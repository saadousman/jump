post_deployment_healthcheck(){
# STEP 2 - CONNECT TO THE CLUSTER
  echo "Azure login"
  export APPSETTING_WEBSITE_SITE_NAME='azcli-workaround'
  az login --identity --username $AZURE_IDENTITY
  az account set --subscription $AZURE_SUBSCRIPTION
  echo "Setting Azure AKS credentials"
  az aks get-credentials --name $AZURE_AKS_CLUSTER_NAME --resource-group $AZURE_AKS_CLUSTER_RESOURCE_GROUP
  # STEP 3 - SET KUBECONFIG
  echo "Configuring Kubectl"
  kubelogin convert-kubeconfig -l azurecli
  # @TODO: Remove yq lines after aks-54uma725.privatelink.uaenorth.azmk8s.io gets added to InfoBlox
  yq e -i '.clusters[].cluster.server = "https://aks-pbky1iij.hcp.uaenorth.azmk8s.io:443"' ~/.kube/config
  yq e -i '.clusters[].cluster.certificate-authority-data = null' ~/.kube/config
  yq e -i '.clusters[].cluster.insecure-skip-tls-verify = true' ~/.kube/config
 
REPLICAS=$(kubectl get $WORKLOAD_TYPE $PRODUCT_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}')
 
# Function to check if all replicas are running
check_replicas_running() {
# STEP 2 - CONNECT TO THE CLUSTER
  echo "Azure login"
  export APPSETTING_WEBSITE_SITE_NAME='azcli-workaround'
  az login --identity --username $AZURE_IDENTITY
  az account set --subscription $AZURE_SUBSCRIPTION
  echo "Setting Azure AKS credentials"
  az aks get-credentials --name $AZURE_AKS_CLUSTER_NAME --resource-group $AZURE_AKS_CLUSTER_RESOURCE_GROUP
  # STEP 3 - SET KUBECONFIG
  echo "Configuring Kubectl"
  kubelogin convert-kubeconfig -l azurecli
  # @TODO: Remove yq lines after aks-54uma725.privatelink.uaenorth.azmk8s.io gets added to InfoBlox
  yq e -i '.clusters[].cluster.server = "https://aks-pbky1iij.hcp.uaenorth.azmk8s.io:443"' ~/.kube/config
  yq e -i '.clusters[].cluster.certificate-authority-data = null' ~/.kube/config
  yq e -i '.clusters[].cluster.insecure-skip-tls-verify = true' ~/.kube/config
 
  READY_REPLICAS=$(kubectl get $WORKLOAD_TYPE "$PRODUCT_NAME" -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
  if [[ "$READY_REPLICAS" == "$REPLICAS" ]]; then
    return 0  # All replicas are running
  else
    return 1  # Not all replicas are running
  fi
}
 
# Retry loop to wait for StatefulSet or Deployment to be fully up and running
MAX_RETRIES=60
SLEEP_TIME=15
 
for (( i=0; i<MAX_RETRIES; i++ )); do
  if check_replicas_running; then
    echo "All $READY_REPLICAS replicas of $WORKLOAD_TYPE '$PRODUCT_NAME' are running."
    # Send notification to admin (replace with your notification system)
    # Example: echo "All replicas are running. Notify admin here."
    exit 0
  else
    echo "Waiting for all replicas to be ready... ($READY_REPLICAS/$REPLICAS)"
  fi
  sleep $SLEEP_TIME
done
 
echo "Timed out waiting for all replicas to be ready."
# Send failure notification (replace with your notification system)
# Example: echo "Replicas not ready. Notify admin here."
exit 1
 
}