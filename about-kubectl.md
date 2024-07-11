# About kubectl

kubectl is the main command for manipulating objects in kubernetes. Here are some of the main commands that are useful:

*`kubectl get pods` - shows all the user made pods (in the default namespace)*

*`kubectl get pods -A` - shows all pods in all namespaces. This include none-user made pods such as kubeedge, container-registry or kube-system pods*

*`kubectl get pods -n <namespace>` - shows only pods in a specific namespace*

*`kubectl get deployments (-A, -n <namespace>)` - shows deployments*

*`kubectl get service (-A, -n <namespace>)` - shows services*

*`kubectl get nodes (-A, -n <namespace>)` - shows nodes*

The 'get' commands retrieve resources from the cluster. You can retrieve one specific object by setting adding the name of the resource after the type of resource (e.g. 'pods'). To do this, make sure you also have set the correct namespace flag if the resource is not in the default namespace.

All kubernetes resources are represented by a yaml object. You can view the yaml directly by passing the flag `-o yaml`. Other possible output formats include `-o json` for a json version of the resource, `-o wide` for a table containing a little more information than the standard table, and `-o jsonpath=<jsonpath>` which is useful to retrieve specific values from the json/yaml resource.

***

## Deployments

A deployments is an object which manages pods. This is what you manipulate when you want to create, scale and update groups of pods.

*`kubectl create deployment <deployment-name> --image=<image-uri> --port=<port> --replicas=<replicas>` - creates a new deployment. The deplyment name is arbitrary. \<image\> must be a uri to a reachable repository. See the registry scripts for how to set up a local repository. Port specifies which port to talk to the pods on. Replicas are how many pods should be scheduled across the entire cluster.*

*`kubectl expose <deployment-name>` - creates a new service that points to a deployment. This makes an arbitrary Cluster IP that can be used to access the pods in the deployment.*

*`kubectl scale deployment <deployment-name> --replicas <number>` - scales the deployment by changing the number of replicas it tries to maintain. The '--replicas' flag is mandatory.*

*`kubectl patch <resource-type> <resource-name> -p <patch>` - simple command to edit a resource. the \<patch\> here is formatted in json. You can find the structure of the resource by running* ***kubectl get \<resource-type\> \<resource-name\> -o json*** *see example in README->Test update rollout of deployments*


## Other kubernetes resources:

- ***Pods:*** Pods are essensially the jobs running in the cluster. Each pod typically represents a container running on a node.
- ***Services:*** A service is how you access groups of pods. They are typically bound to a deployment, and provide a shared IP for all the pods in the deployment. It some load balancing between the pods.
- ***Replicasets:*** This is what a deplyment uses to maintain the number of desired pods. A replicaset's job is to maintain X amount of a given pod. If a node goes offline, it will reschedule pods onto other nodes.
- ***Daemonsets:*** These sets ensure that one copy of a given pod is run on each node. If a new node comes online, it will schedule a pod from the daemonset if it matches the conditions. These are typically only used for system processes in kubernetes, but can be practical as a service in our use case.


