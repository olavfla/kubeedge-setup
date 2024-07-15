#Run on controller
#Tear down
microk8s disable registry
microk8s disable hostpath-storage:destroy-storage
#Set up
kubectl cordon -l 'node-role.kubernetes.io/edge'
microk8s enable registry
export REGISTRY_ENDPOINT=$(kubectl get service -n container-registry registry -o jsonpath={.spec.clusterIP}):5000
mkdir -p /var/snap/microk8s/current/args/certs.d/$REGISTRY_ENDPOINT
cat <<EOF > /var/snap/microk8s/current/args/certs.d/$REGISTRY_ENDPOINT/hosts.toml
server = "http://$REGISTRY_ENDPOINT"

[host."http://$REGISTRY_ENDPOINT"]
    capabilities = ["pull", "resolve"]

EOF
sudo snap install docker
sudo snap install jq
sudo jq --arg endpoint "$REGISTRY_ENDPOINT" 'if .["insecure-registries"] then
    if (.["insecure-registries"] | index($endpoint)) == null then
        .["insecure-registries"] += [$endpoint]
    else
        .
    end
else
    .["insecure-registries"] = [$endpoint]
end' /var/snap/docker/current/config/daemon.json > ~/daemon.tmp && sudo mv ~/daemon.tmp /var/snap/docker/current/config/daemon.json
sudo snap restart docker
kubectl uncordon -l 'node-role.kubernetes.io/edge'
echo -e "\033[1;36mSetup complete. Continue with \033[0;31mRegistry_EdgeCore.sh\033[1;36m on each of the edge nodes. You can verify that the registry is working by visiting \033[0;31m${REGISTRY_ENDPOINT}/v2/_catalog\033[0m"
echo -e "\033[1;36mAlso, use the above IP for \033[0;31mRegistry_EdgeCore.sh\033[0m"