if [ "$#" -ne 1 ]; then
    echo "Usage: source Daemonset_expose.sh <daemonset-name>"
    return 1
fi
DAEMON_NAME=$1
export DAEMON_PORT=$(kubectl get daemonset $DAEMON_NAME -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}')
if [ -z "$DAEMON_PORT" ]; then
    echo "Failed to retrieve the port. Please ensure the DaemonSet specifies a container port."
    return 1
fi
cat <<EOF > service_tmp.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${DAEMON_NAME}-service
spec:
  selector:
    name: $DAEMON_NAME
  ports:
  - protocol: TCP
    port: $DAEMON_PORT
    targetPort: $DAEMON_PORT
EOF
kubectl apply -f service_tmp.yaml
rm service_tmp.yaml