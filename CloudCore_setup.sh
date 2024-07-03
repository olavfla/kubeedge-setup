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
wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.0/keadm-v1.17.0-linux-amd64.tar.gz
tar -zxvf keadm-v1.17.0-linux-amd64.tar.gz
sudo mkdir -p /usr/local/bin
sudo cp keadm-v1.17.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
### Uncomment next line to automatically get IP from the cluster API. This might not be the address you want ###
#CLOUD_CONTROLLER_IP=$(sudo kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
keadm init --advertise-address=${CLOUD_CONTROLLER_IP} --kube-config=$HOME/.kube/config --set cloudCore.modules.dynamicController.enable=true
echo "Setup complete! I advise you to reboot, that way microk8s/kubectl can run without sudo."