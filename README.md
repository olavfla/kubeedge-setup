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
Calico is a container network interface (CNI) that is required by microk8s nodes in order for them to run pods. This, however, does not work innately on edge nodes, so we use edgemesh instead. The controller will still create malfunctioning calico pods on each edge node. Removal of these have been moved into CloudCore_setup.sh

# Setting up the registry

Setting up the registry is done in two steps:
- Setting up the registry on the cloud node
- Configuring the edge nodes to be able to pull from the insecure registry.

*(on controller:)*

`> source Registry_CloudCore.sh`

*(on edge:)*

`> source Registry_EdgeCore.sh`

*(registry can be tested from cloud:)*

`> source Registry_test.sh` 

## How to upload to the registry with docker.

To upload a new image to the registry, first pull the pull or create the image on the node with the registry:

`sudo docker pull <image>`

Then tag it as follows:

`sudo docker tag <image-id> 127.0.0.1:32000/<image-name>:<tag>`

Here, the \<image-name\> and \<tag\> can chosen freely.


Finally, push the image to the registry:

`sudo docker push 127.0.0.1:32000/<image-name>:<tag>`

An example of this can be found in the Registry_test.sh script.

When setting the image in your cloud applications, you must use the Service IP. Otherwise, the image will fail to pull.

# Test rollout and scaling of deployments

Doing this takes very few commands, and there are a lot if things that can be varied, such as number of replicas of the deployments, which image to use, etc.

Instead of making a fully automated script, i will instead include some examples of how to create, scale and update deployments here (with example images) and you can change images or number of replicas as you see fit.

I recommend reading about-kubectl.md for a short intro to kubernetes resources and commands

First off, create a deployment:

`kubectl create deployment alpaca-prod --image=gcr.io/kuar-demo/kuard-amd64:blue --port=8080 --replicas=12`

You can set the number of replicas when creating the deployment, or aftarwards with:

`kubectl scale deployment alpaca-prod --replicas 20`

Then you can trigger an update rollout by editing the deployment and changing the image:

`kubectl patch deployment alpaca-prod -p '{"spec":{"template":{"spec":{"containers":[{"name":"kuard-amd64","image":"gcr.io/kuar-demo/kuard-amd64:green","imagePullPolicy":"Always"}]},"metadata":{"annotations":{"kubernetes.io/change-cause":"Update to kuard green"}}}}}'` 

This will chenge the desired image for the deployment, and it will automatically start the rollout proccess to update the pods to the new image.

And finally view the status of the rollout:

`kubectl rollout status deployments alpaca-prod`

When you do this while measuring network traffic, i recommend waiting until the previous command has finished before issuing any other commands. The `kubectl patch` command will take a while to finish rolling out the new updated image, and the `kubectl rollout` will only exit when the rollout is complete. The traffic generated in this process is very relevant for testing, and probably pretty high as well.

If you want to change the image back and forth, you can use this command to set it back to the 'blue' image:

`kubectl patch deployment alpaca-prod -p '{"spec":{"template":{"spec":{"containers":[{"name":"kuard-amd64","image":"gcr.io/kuar-demo/kuard-amd64:blue","imagePullPolicy":"Always"}]},"metadata":{"annotations":{"kubernetes.io/change-cause":"Update to kuard blue"}}}}}'`

If you want to test this out with the local registry, all you have to do is to swap out the 'image', both when creating and patching the deployment, as well as changing the 'name' field. The name field is important to get right, as it serves as a merge key for the container to be updated. The default name is the name of the image.

# Daemonsets

Daemonsets are similar to deployments/replicasets in that they maintain a number of pods. The distiction however is that a daemonset ensures that one pod is running on each qualified node. Daemonsets are typically not used for services, but i think it can be practical for our use case (such as each node with sensors running a data collecting proccess).

Unfortunately daemonsets are not as easy to create as deployments, since they are not intended to be used as services. I have made some scripts to make creating a simple daemonset as easy as making a deployment.

**Everything here is run on controller**

*(to create a new daemonset:)*

`source Daemonset_create.sh <daemonset-name> <image-uri> (optional <port>)`

*(then to create a service to access it:)*

`source Daemonset_expose.sh <daemonset-name>`

Now you can run `kubectl get service` to see which IP you can access the service from.
