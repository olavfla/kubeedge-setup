if [ "$#" -lt 2 ]; then
    echo "Usage: source Daemonset_create.sh <daemonset-name> <image-uri> (optional <port>)"
    return 1
fi
export DAEMON_NAME=$1
export DAEMON_IMAGE=$2
export DAEMON_IMG_NAME=$(basename "$DAEMON_IMAGE" | cut -d':' -f1)
if [ "$#" -eq 3 ]; then
    export DAEMON_PORT=$3
else
    export DAEMON_PORT=""
fi
cat <<EOF > daemonset_tmp.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: $DAEMON_NAME
spec:
  selector:
    matchLabels:
      name: $DAEMON_NAME
  template:
    metadata:
      labels:
        name: $DAEMON_NAME
    spec:
      containers:
      - name: $DAEMON_IMG_NAME
        image: $DAEMON_IMAGE
EOF

if [ -n "$DAEMON_PORT" ]; then
    cat <<EOF >> daemonset_tmp.yaml
        ports:
        - containerPort: $DAEMON_PORT
          protocol: TCP
EOF
fi
kubectl apply -f daemonset_tmp.yaml
rm daemonset_tmp.yaml