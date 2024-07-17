#Run on controller
export REGISTRY_ENDPOINT="127.0.0.1:32000"
kubectl delete deployment alpaca-registry-test
kubectl delete service alpaca-registry-test
sleep 5
sudo docker pull gcr.io/kuar-demo/kuard-amd64:blue
sudo docker tag $(sudo docker images gcr.io/kuar-demo/kuard-amd64 --format "{{.ID}}") $REGISTRY_ENDPOINT/example-image:registry
sudo docker push $REGISTRY_ENDPOINT/example-image:registry
kubectl create deployment alpaca-registry-test --image="$REGISTRY_ENDPOINT/example-image:registry" -r 4 --port=8080
kubectl expose deployment alpaca-registry-test
sleep 5
export SERVICE_IP="$(kubectl get service alpaca-registry-test -o jsonpath={.spec.clusterIP})"
echo -e "\033[1;36mService running on \033[0;31m$SERVICE_IP:8080\033[1;36m. Verify in browser (or curl).\033[0m"
echo -e "\033[1;36mPlease check that all alpaca-registry-test pods are \033[0;31m'Running'\033[0m"
echo -e "\033[1;36mIf pods have status \033[0;31m'ErrImagePull'\033[1;36m or \033[0;31m'ImagePullBackOff'\033[1;36m, or no resources are found in default namespace, the registry has either failed or is not initialized yet.\033[0m"
kubectl get pods -l app=alpaca-registry-test -o wide





