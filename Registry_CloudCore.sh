#Run on controller
#Tear down
microk8s disable registry
microk8s disable hostpath-storage:destroy-storage
#Set up
kubectl cordon -l 'node-role.kubernetes.io/edge'
microk8s enable registry
sleep 10
#Find the registry
export REGISTRY_ENDPOINT=$(kubectl get pods -n container-registry -o jsonpath={.items[0].status.hostIP})
while [ -z "$REGISTRY_ENDPOINT" ]; 
do
    sleep 5
    export REGISTRY_ENDPOINT=$(kubectl get pods -n container-registry -o jsonpath={.items[0].status.hostIP})
done
REGISTRY_ENDPOINT=$REGISTRY_ENDPOINT:32000
echo "Registry found at $REGISTRY_ENDPOINT"
#Configure
mkdir -p /var/snap/microk8s/current/args/certs.d/$REGISTRY_ENDPOINT
cat <<EOF > /var/snap/microk8s/current/args/certs.d/$REGISTRY_ENDPOINT/hosts.toml
server = "http://$REGISTRY_ENDPOINT"

[host."http://$REGISTRY_ENDPOINT"]
    capabilities = ["pull", "resolve"]

EOF
kubectl uncordon -l 'node-role.kubernetes.io/edge'
echo "Setup complete. Continue with Registry_EdgeCore.sh on each of the edge nodes. You can verify that the registry is working by visiting ${REGISTRY_ENDPOINT}/v2/_catalog"

