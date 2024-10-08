#Run on controller
#Running this will reset the controller, so you'll have to rejoin edge nodes.
if [ "$#" -ne 1 ]; then
    echo "Usage: source CloudCore_setup.sh <IP>"
    return 1
fi

CLOUD_CONTROLLER_IP=$1
if [ -z "${USERNAME}" ]; then
    USERNAME=$USER
fi

sudo snap install microk8s --classic --channel=1.30
sudo usermod -a -G microk8s $USERNAME
mkdir ~/.kube
sudo chown -R $USERNAME ~/.kube
sudo microk8s config >> ~/.kube/config
sudo snap alias microk8s.kubectl kubectl
if [ ! -f "keadm-v1.17.0-linux-amd64.tar.gz" ]; then
    wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.0/keadm-v1.17.0-linux-amd64.tar.gz
fi
tar -zxvf keadm-v1.17.0-linux-amd64.tar.gz
sudo mkdir -p /usr/local/bin
sudo cp keadm-v1.17.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
### Uncomment next line to automatically get IP from the cluster API. This might not be the address you want ###
#CLOUD_CONTROLLER_IP=$(sudo kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
sudo keadm reset cloud --kube-config $HOME/.kube/config --force
sudo kubectl delete pods -n kubeedge --all --force
sleep 5
keadm init --advertise-address=${CLOUD_CONTROLLER_IP} --kube-config=$HOME/.kube/config --set cloudCore.modules.dynamicController.enable=true
ret=$?
sudo kubectl patch daemonsets.apps -n kube-system calico-node -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"node-role.kubernetes.io/edge","operator":"DoesNotExist"}]}]}}}}}}}'
sudo kubectl patch deployments.apps -n kube-system coredns -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"node-role.kubernetes.io/edge","operator":"DoesNotExist"}]}]}}}}}}}'
if [ ${ret} == "0" ]; then
    echo -e "\033[1;36mSetup complete! I advise you to \033[0;31mreboot\033[1;36m, that way microk8s/kubectl can run without sudo. Some later script depend on this.\033[0m"
    return 1
else
    echo -e "\033[1;36mInitializing CloudCore failed...\033[0m"
fi