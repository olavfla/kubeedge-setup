if [ "$#" -lt 2 ]; then
    echo "Usage: source EdgeCore_setup.sh <CloudCore IP> <token> | <'--ssh' (user)>"
    return 1
fi

CLOUD_CONTROLLER_IP=$1

if [ "$2" == "--ssh" ]; then
    echo "Getting token with ssh"
    if [ "$#" -eq 3 ]; then
        token=$(ssh ${3}@${CLOUD_CONTROLLER_IP} "keadm gettoken --kube-config=$HOME/.kube/config")
    else
        token=$(ssh ${USER}@${CLOUD_CONTROLLER_IP} "keadm gettoken --kube-config=$HOME/.kube/config")
    fi
    echo "Token is $token"
else
    token=$2
fi


wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.0/keadm-v1.17.0-linux-amd64.tar.gz
tar -zxvf keadm-v1.17.0-linux-amd64.tar.gz
sudo mkdir -p /usr/local/bin
sudo cp keadm-v1.17.0-linux-amd64/keadm/keadm /usr/local/bin/keadm
wget https://github.com/containerd/containerd/releases/download/v1.7.18/containerd-1.7.18-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.18-linux-amd64.tar.gz
sudo mkdir -p /usr/local/lib/systemd/system
sudo wget -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
wget https://github.com/opencontainers/runc/releases/download/v1.1.13/runc.amd64
sudo mkdir -p /usr/local/sbin
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz
sudo mkdir -p /etc/cni/net.d/
sudo sh -c 'cat >/etc/cni/net.d/bridge.conf <<EOF
{
  "cniVersion": "0.3.1",
  "name": "containerd-net",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.88.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
EOF'
sudo mkdir -p /etc/containerd
sudo touch /etc/containerd/config.toml
sudo sh -c 'containerd config default > /etc/containerd/config.toml'
sudo systemctl restart containerd
sudo keadm reset edge
sudo rm -rf /etc/kubeedge/*
sudo keadm join --cloudcore-ipport=${CLOUD_CONTROLLER_IP}:10000 --token=${token} --kubeedge-version=v1.17.0 --remote-runtime-endpoint=unix:///run/containerd/containerd.sock
sudo snap install yq
sudo cat /etc/kubeedge/config/edgecore.yaml | yq '.modules.metaManager.metaServer.enable=true' | sudo tee /etc/kubeedge/config/edgecore.tmp
sudo mv /etc/kubeedge/config/edgecore.tmp /etc/kubeedge/config/edgecore.yaml
sudo cat /etc/kubeedge/config/edgecore.yaml | yq '.modules.edged.tailoredKubeletConfig.clusterDNS[0]="169.254.96.16"' | sudo tee /etc/kubeedge/config/edgecore.tmp
sudo mv /etc/kubeedge/config/edgecore.tmp /etc/kubeedge/config/edgecore.yaml
sudo cat /etc/kubeedge/config/edgecore.yaml | yq '.modules.edged.tailoredKubeletConfig.clusterDomain="cluster.local"' | sudo tee /etc/kubeedge/config/edgecore.tmp
sudo mv /etc/kubeedge/config/edgecore.tmp /etc/kubeedge/config/edgecore.yaml
sudo systemctl daemon-reload
sudo systemctl restart edgecore.service