#Run on contoller
psk_file="$HOME/edgemesh_psk.txt"

if [[ -f "$psk_file" ]]; then
    psk=$(cat "$psk_file")
else
    psk=$(openssl rand -base64 32)
echo "$psk" >> "$psk_file"
fi

if sudo microk8s helm3 ls --namespace kubeedge | grep -q 'edgemesh'; then
    helm_cmd="sudo microk8s helm3 upgrade"
else
    helm_cmd="sudo microk8s helm3 install"
fi

helm_cmd+=" edgemesh --namespace kubeedge --set agent.psk=$psk"
helm_cmd_nodes=( $(sudo kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name},{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}') )

for i in "${!helm_cmd_nodes[@]}"; do
    IFS=',' read -r hostname ip <<< "${helm_cmd_nodes[$i]}"
    helm_cmd+=" --set agent.relayNodes[$i].nodeName=$hostname,agent.relayNodes[$i].advertiseAddress=\"{$ip}\""
done

helm_cmd+=" https://raw.githubusercontent.com/kubeedge/edgemesh/main/build/helm/edgemesh.tgz"
eval "$helm_cmd"