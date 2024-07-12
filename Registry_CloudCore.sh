#Run on controller
#Tear down
if [ "$#" -ne 1 ]; then
    echo "Usage: source Registry_CloudCore.sh <Cloud IP>"
    return 1
fi
microk8s disable registry
microk8s disable hostpath-storage:destroy-storage
#Set up
kubectl cordon -l 'node-role.kubernetes.io/edge'
microk8s enable registry
sleep 10
#Find the registry
export REGISTRY_ENDPOINT=$1
while [ -z "$REGISTRY_READY" ]; 
do
    sleep 5
    export REGISTRY_READY=$(kubectl get pods -n container-registry -o jsonpath={.items[0].status.hostIP})
done
REGISTRY_ENDPOINT=$REGISTRY_ENDPOINT:32000
echo "Registry ready"
#Configure
mkdir -p /var/snap/microk8s/current/args/certs.d/$REGISTRY_ENDPOINT
cat <<EOF > /var/snap/microk8s/current/args/certs.d/$REGISTRY_ENDPOINT/hosts.toml
server = "http://$REGISTRY_ENDPOINT"

[host."http://$REGISTRY_ENDPOINT"]
    capabilities = ["pull", "resolve"]

EOF
kubectl uncordon -l 'node-role.kubernetes.io/edge'
echo -e "\033[1;36mSetup complete. Continue with \033[0;31mRegistry_EdgeCore.sh\033[1;36m on each of the edge nodes. You can verify that the registry is working by visiting \033[0;31m${REGISTRY_ENDPOINT}/v2/_catalog\033[0m"

