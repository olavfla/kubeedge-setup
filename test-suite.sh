#This script is tailored to our specific testing setup, and might not work due to certain assumptions that it makes (such as interface name, node IPs, node username/passwords etc.). Included for documentation purposes
quickcap() {
    if [ $# -ne 1 ]; then
        echo "Usage: quickcap <seconds>"
        return 1
    fi
    NODES=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' -l node-role.kubernetes.io/edge)
    MAC_ADDRESSES=($(ip link show "$(ip route | awk '/default/ {print $5}')" | awk '/ether/ {print $2}'))
    for IP in $NODES; do
        MAC=$(arp -n $IP | awk '/ether/ {print $3}')
        if [ -n "$MAC" ]; then
            MAC_ADDRESSES+=("$MAC")
        fi
    done
    echo "Found Node IPS"
    CAPTURE_FILTER="ether host ${MAC_ADDRESSES[0]}"
    for MAC in "${MAC_ADDRESSES[@]:1}"; do
        CAPTURE_FILTER="$CAPTURE_FILTER or ether host $MAC"
    done
    FILEN=0
    while [ -f "cap_${FILEN}.pcapng" ]; do
        FILEN=$(( $FILEN + 1 ))
    done
    FILENAME="cap_${FILEN}.pcapng"
    touch ${FILENAME}
    sudo chmod 666 ${FILENAME}
    echo "Writing to file ${FILENAME}"
    sudo tshark -i eno1 -f "${CAPTURE_FILTER}" -w ${FILENAME} -a duration:$1
    echo "Capture complete"
}

netem_all() {
    if [ $# -ne 1 ]; then
        echo "Usage: netem_all <profile> (none, tacbb or satcom)"
        return 1
    fi
    export NETEM_PRE
    export NETEM_POST
    if [ "$1" == "none" ]; then
        NETEM_PRE="tc qdisc del dev"
        NETEM_POST="root"
        sudo tc qdisc del dev eno1 root
    fi
    if [ "$1" == "tacbb" ]; then
        NETEM_PRE="tc qdisc add dev"
        NETEM_POST="root netem rate 2mbit delay 100ms loss 1%"
    fi
    if [ "$1" == "satcom" ]; then
        NETEM_PRE="tc qdisc add dev"
        NETEM_POST="root netem rate 250kbit delay 550ms"
    fi

    NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' -l node-role.kubernetes.io/edge)
    for IP in $NODE_IPS; do
        PRIMARY_IFACE=$(ssh -o "StrictHostKeyChecking=no" -o "BatchMode=yes" $IP "ip route | grep default | awk '{print \$5}'")
        if [ -n "$PRIMARY_IFACE" ]; then
            ssh -o "StrictHostKeyChecking=no" -o "BatchMode=yes" $IP "echo <password> | sudo -S $NETEM_PRE $PRIMARY_IFACE $NETEM_POST"
            echo "Set netem $1 for $IP"
        else
            echo "Primary iface not found for node $IP"
        fi
    done
    if [ "$1" == "tacbb" ]; then
        sudo tc qdisc add dev eno1 root netem rate 2mbit delay 100ms loss 1%
    fi
    if [ "$1" == "satcom" ]; then
        sudo tc qdisc add dev eno1 root netem rate 250kbit delay 550ms
    fi
}

test_suite() {
    netem_all none
    kubectl delete deployment alpaca-prod
    sleep 180
    kubectl delete pods --all --force
    sleep 30
    echo "Starting capture"
    quickcap 600
    netem_all none
    netem_all tacbb
    quickcap 600
    netem_all none
    netem_all satcom
    quickcap 600
    netem_all none
    kubectl create deployment alpaca-prod --image=gcr.io/kuar-demo/kuard-amd64:blue --port=8080 --replicas=40
    sleep 300
    quickcap 600
    netem_all none
    netem_all tacbb
    quickcap 600
    netem_all none
    netem_all satcom
    quickcap 600
    netem_all none
    kubectl scale deployment alpaca-prod --replicas=80
    sleep 300
    quickcap 600
    netem_all none
    netem_all tacbb
    quickcap 600
    netem_all none
    netem_all satcom
    quickcap 600
    netem_all none
}
