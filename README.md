# Configuring the cluster from scratch

Deploying the cluster must be done in three steps:
- Setting up the controller (microk8s & CloudCore)
- Adding edge nodes (EdgeCore)
- Deploying EdgeMesh

If you wish to add more edge nodes after the initial setup, you simply have to run the **EdgeCore_setup** script on the edge nodes you want to add, and then redeploy the edgemesh by running the **EdgeMesh_setup** script on the controller.

It is advised that you restart sometime after setting up the CloudCore, since it lets you run microk8s commands without sudo, although this is not neseccary for the installation.

The **CloudCore_setup** script need one parameter to run: ***the exposed IP***.

The **EdgeCore_setup** script needs two parameters to run: the CloudCore's ***exposed IP*** and a ***token*** from the controller node.

The token can be generated with the command `keadm gettoken --kube-config=$HOME/.kube/config`. The same token can be used for all edge nodes.

Alternativly, you can run the **EdgeCore_setup** script with the --ssh flag (followed by username, defaults to $USERNAME if no username is provided) to try to get the token from the exposed IP via SSH

## Example
*(on controller:)*

`> source CloudCore_setup.sh 192.168.1.10`

*(then on edge either:)*

`> source EdgeCore_setup.sh 192.168.1.10 --ssh user1`

*(or:)*

`> source EdgeCore_setup.sh 192.168.1.10 4fWjEGRZ+5gf/3A+aiKzBxXPwBOrY8eZLpm+agVXm5st...`

*(finally, on controller:)*

`> source EdgeMesh_setup.sh`

## Notes
The microk8s node (the controller) will automatically turn on some basic services such as DNS and calico.
Calico is a container network interface (CNI) that is required by microk8s nodes in order for them to run pods. This, however, does not work innately on edge nodes, so we use edgemesh instead. The controller will still create malfunctioning calico pods on each edge node. These are not harmful, but can be removed by editing the calico-node daemonset:

# Setting up the registry

Setting up the registry is done in two steps:
- Setting up the registry on the cloud node
- Configuring the edge nodes to be able to pull from the insecure registry.

These must be done in order in order to know the address of the insecure registry.
*(on controller:)*

`> source Registry_CloudCore.sh`

*(on edge:)*

`> source Registry_EdgeCore.sh <Cloud IP>`

*(registry can be tested from cloud:)*

`> source Registry_test.sh`