<div align="center"><img src="https://github.com/user-attachments/assets/3024ad1d-944f-491f-8df0-9389ff95dc06" width="100"/></div>

<h1 align="center">Infrastructure code for Public Dev/Testnets Setup</h1>

This repository contains the infrastructure code used to setup a dev/testnet. This setup uses [Kurtosis](https://docs.kurtosis.com/) and the [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview) for setting up a public devnet available for other nodes to join and participate in the network.

# Infrastructure Setup
To create a new testnet using the infrastructure scripts in this repository, follow these steps:

## Setup a GKE cluster
1. [Install](https://cloud.google.com/sdk/docs/install-sdk) gcloud cli
> Note: After enabling billing, copy the billing account ID.

2. Run the setup-gke.sh script
- Make the script executable
```bash
chmod +x setup-gke.sh
```
- Run the script using the billing account ID you copied from the first step
```bash
./setup-gke.sh <billing_acc_id>
```
> Note: You can change other settings from the defaults such as `region` and `zone` directly in the script

> Note: Wait a minute or two for the enabled API's enabling to propagate if you get this error:

> `ERROR: (gcloud.container.clusters.create) ResponseError: code=403, message=Kubernetes Engine API has not been used in project`

- The script does a few things:
  - Creates a new project on google cloud console or dashboard called `ethereum-private-test-network`
  - Enables `Artifact Registry` and Google `Kubernetes Engine` APIs.
  - Creates a standard GKE cluster needed for deploying the necessary artifacts by `kurtosis`
  - Fetches authentication credentials for the created GKE cluster and updates your local `kubeconfig` file (usually at ~/.kube/config) with the cluster's endpoint and credentials.
      - This enables us to execute commands on our GKE cluster using the `kubectl` cli
  - Creates a static IP address for the loadbalancer we'll create to access our Ethereum Nodes

3. Install kubectl as detailed [here](https://kubernetes.io/docs/tasks/tools/#kubectl)
> Note: Step 2 has already updated you `kubeconfig`
> 
 



## Setup Kubernetes Commandline Tool (Kubectl)
1. 

## Setup Kurtosis
1. 

# Deploying Services

## Spinup initial network nodes
1. 

## Deploy a loadbalancer service
1. 

## Deploy a participating node (optional)
1. 
