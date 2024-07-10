#Run on controller
kubectl delete deployment alpaca-registry-test
kubectl delete service alpaca-registry-test
sudo snap install docker
export REGISTRY_ENDPOINT=$(kubectl get pods -n container-registry -o jsonpath={.items[0].status.hostIP})
if [ -z "$REGISTRY_ENDPOINT" ]; then
    echo "Unable to find registry"
    return 1
fi
REGISTRY_ENDPOINT=$REGISTRY_ENDPOINT:32000
cat <<EOL > ~/daemon.tmp
{
    "log-level":    "error",
    "insecure-registries" : ["$REGISTRY_ENDPOINT"]
}
EOL
sudo mv ~/daemon.tmp /var/snap/docker/current/config/daemon.json
sudo snap restart docker
sleep 5
sudo docker pull gcr.io/kuar-demo/kuard-amd64:blue
sudo docker tag $(sudo docker images gcr.io/kuar-demo/kuard-amd64 --format "{{.ID}}") $REGISTRY_ENDPOINT/example-image:registry
sudo docker push $REGISTRY_ENDPOINT/example-image:registry
kubectl create deployment alpaca-registry-test --image="$REGISTRY_ENDPOINT/example-image:registry" -r 4 --port=8080
kubectl expose deployment alpaca-registry-test
sleep 5
export SERVICE_IP="$(kubectl get service alpaca-registry-test -o jsonpath={.spec.clusterIP})"
echo "Service running on $SERVICE_IP:8080. Verify in browser"
echo "Please check that all alpaca-registry-test pods are 'Running'"
kubectl get pods -o wide





