#Run on edge
#Must be run after EdgeCore_setup.sh
REGISTRY_ENDPOINT="127.0.0.1:32000"
#Find the correct line in the config
export CONFIG_LINE=$(cat /etc/containerd/config.toml | grep '\[plugins."io.containerd.grpc.v1.cri".registry.mirrors\]' -n | cut -f1 -d:)
echo "Editing /etc/containerd/config.toml:"
sudo sed -i -e "$((CONFIG_LINE+1)), $((CONFIG_LINE+2))s/^        .*$//" \
    -e "$((CONFIG_LINE+1))i\\
        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"$REGISTRY_ENDPOINT\"]\\
        endpoint = [\"http://$REGISTRY_ENDPOINT\"]" \
    /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep -A 3 '\[plugins."io.containerd.grpc.v1.cri".registry.mirrors\]' -n
sudo systemctl restart containerd.service
sudo systemctl daemon-reload