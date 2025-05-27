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
  - Fetches authentication credentials for the created GKE cluster and updates your local `kubeconfig` file (usually at `~/.kube/config`) with the cluster's endpoint and credentials.
      - This enables us to execute commands on our GKE cluster using the `kubectl` cli
  - Creates a static IP address for the loadbalancer we'll create to access our Ethereum Nodes.
    > Note: Take note of this IP address because it'll be used in step 2 of [Spinup initial network nodes](#spinup-initial-network-nodes) section.

## Setup Kubernetes Commandline Tool (Kubectl)
1. Install kubectl as detailed [here](https://kubernetes.io/docs/tasks/tools/#kubectl)
- Step 2 in the [previous](#setup-a-gke-cluster) section has already updated `kubeconfig` file for you. To view it with VS code:
  - Open VS code and open a terminal in VS code
  - Use VS Code to open the file: using the command below:
    ```bash
    code ~/.kube/config
    ```
  - If code is not recognized, you need to enable the code command in your shell:
    - Open VS Code.
    - Press `Cmd + Shift + P` to open the Command Palette.
    - Type `Shell Command: Install 'code' command in PATH` and hit Enter.
    - Restart Terminal and try again

## Setup Kurtosis
1. Install Kurtosis following this [guide](https://docs.kurtosis.com/install).
    > Note: On a macbook you must have Xcode > 16. To update, go to system settings -> software update.

2. Configure your kurtosis file
  - Get your local kurtosis config yml path by running the command below:
    ```bash
    kurtosis config path
    ```
  - Navigate to the path shown and open the `kurtosis-config.yml` file using the nano command-line text editor:
    ```bash
    nano <path/kurtosis/kurtosis-config.yml>
    ```
  - Copy the `kurtosis-config.yml` file that is in this repository and put it in that file.
    > Note: Change the kubernetes-cluster-name under the cloud section if it is different
  - Run the command below to setup kurtosis to use the cloud kubernetes cluser:
    ```bash
    kurtosis cluster set cloud
    ```
  - Run the command below in a separate terminal. It acts as a middle man between your computer's ports and your services deployed on Kubernetes ports and has to stay running as a separate process.
    ```bash
    kurtosis gateway
    ```

# Deploying Services

We are going to follow this guide for [spinning up a private network using kurtosis](https://geth.ethereum.org/docs/fundamentals/kurtosis). The difference is we are spinning it up on a GKE cluster instead of a locally using docker.

## Spinup initial network nodes
1. We'll setup a few parameters in the file `network_params.yaml`. You can check the [ethereum kurtuosis package](https://github.com/ethpandaops/ethereum-package?tab=readme-ov-file#configuration) for more details on the parameters you can set.
    - Change the `network_id` parameter to be some unique number. Find more details here for [choosing a network ID](https://geth.ethereum.org/docs/fundamentals/kurtosis#choosing-network-id).
    - Change the `nat_exit_ip` to be the static IP address from step 2 of the [Setup a GKE cluster](#setup-a-gke-cluster) section.
2. To spin up the network on our Kubernetes cluster we'll run the command below. You can find more details on the [spinning up the network guide](https://geth.ethereum.org/docs/fundamentals/kurtosis#spinning-up-the-network)
    ```bash
    kurtosis run github.com/ethpandaops/ethereum-package --args-file ./network_params.yaml --image-download always
    ```
    - Copy the name of the enclave that was created when you ran the command above. It looks like the image below. The enclave is called `bold-volcano` in this case:
<div align="center"><img width="710" alt="image" src="https://github.com/user-attachments/assets/06e0122b-8278-4355-9cf5-b9517a39ed6d" /></div>

## Deploy a loadbalancer service
Now we'll deploy a loadbalancer service that will expose the necessary ports for our consensus and execution clients to connect with other peers and to act as a bootstrap node for other nodes that request to join the dev network.
1. Get the name of the `kurtosis enclave` with the nodes created by kurtosis from the output generated in part 2 of the [previous](#spinup-initial-network-nodes) section e.g. bold-volcano.
2. The GKE cluster name space name will be `kt-<enclave name>` e.g. kt-bold-volcano
3. Run the command below to create the loadbalancer service. Use the GKE cluster name space from above as the first parameter and the IP address from step 2 of the `Setup a GKE cluster` as the second parameter:
   ```bash
   NAMESPACE=<gke_cluster_namespace> IP=<loadbalancer_static_ip> envsubst < loadbalancer-service.yml | kubectl apply -f -
   ```
   - This command will start a loadbalancer service enabling other consensus nodes to bootstrap from the consensus client using port 4000 and other execution nodes to bootstrap from the execution node using port 30303.
4. Check the status of your nodes.
   - To check the status of your `execution` node run this curl request:
     ```bash
     curl -s -X POST http://<loadbalancer_static_ip>:8545  \                                                                   
      -H "Content-Type: application/json" \
      --data '{
        "jsonrpc":"2.0",
        "method":"admin_nodeInfo",
        "params":[],
        "id":1
      }'
     ```
     The output will be similar to the one below. Take note of the `enode` field. It is used for bootstrapping other execution clients/nodes.
     ```json
     {
      "jsonrpc": "2.0",
      "id": 1,
      "result": {
        "id": "bbb3b34026512b38c21ef0eb8f513b523f6f8f96ce83b02a1bbeaa4ae00aea84",
        "name": "Geth/v1.15.12-unstable-7e792546-20250516/linux-amd64/go1.24.3",
        "enode": "enode://4778ea8ed02e9cb2eb40985ed0f3218d66781cb28806024a80824b6cc5dddd872c1e14e8a82c329fe952d01c723e0fbe44fab429b561c63d6c58d137cc7c447b@34.10.136.98:30303",
        "enr": "enr:-KO4QFuIfBvf3fkbzVGchc9wm5N3e12e6SKS1QvkeOnIUF3aUL52mNJyONd4Q2w438KJ5gtrHb-1_Fdo_ADwuf6OWy-GAZb9IdOqg2V0aMfGhNK_fmaAgmlkgnY0gmlwhCIKiGKJc2VjcDI1NmsxoQNHeOqO0C6csutAmF7Q8yGNZngcsogGAkqAgktsxd3dh4RzbmFwwIN0Y3CCdl-DdWRwgnZf",
        "ip": "34.10.136.98",
        "ports": {
          "discovery": 30303,
          "listener": 30303
        },
        "listenAddr": "[::]:30303",
        "protocols": {
          "eth": {
            "network": 9223372036854,
            "genesis": "0x03bcfa40d4dbfa5723664ae626b00f6b6d4e071da994012c8c4349f720d1ad57",
            "config": {
              "chainId": 9223372036854,
              "homesteadBlock": 0,
              "eip150Block": 0,
              "eip155Block": 0,
              "eip158Block": 0,
              "byzantiumBlock": 0,
              "constantinopleBlock": 0,
              "petersburgBlock": 0,
              "istanbulBlock": 0,
              "berlinBlock": 0,
              "londonBlock": 0,
              "mergeNetsplitBlock": 0,
              "shanghaiTime": 0,
              "cancunTime": 0,
              "pragueTime": 0,
              "terminalTotalDifficulty": 0,
              "depositContractAddress": "0x00000000219ab540356cbb839cbe05303d7705fa",
              "blobSchedule": {
                "cancun": {
                  "target": 3,
                  "max": 6,
                  "baseFeeUpdateFraction": 3338477
                },
                "prague": {
                  "target": 6,
                  "max": 9,
                  "baseFeeUpdateFraction": 5007716
                }
              }
            },
            "head": "0x4056c1cd3763371d5c213c9677f8a80a0db4e5edf071d1848ee5a5348d4f96da"
          },
          "snap": {}
        }
      }
     }
     ```
   - To check the status of your `consensus` node run this curl request:
     ```bash
     curl http://<loadbalancer_static_ip>:4000/eth/v1/node/identity
     ```
     The output will be similar to the one below. Take note of the `enr` field. It is used for bootstrapping other consensus clients/nodes:
     ```json
     {
      "data": {
        "peer_id": "16Uiu2HAmVG45m3hxShsGJVhPQbPmz2roL1soSp3JakZoG4iPbLob",
        "enr": "enr:-        N24QGbQYFILLtFjsCu_as8lgMC2hj_8Sgm9vD4yzui0rtpHLsK26EUXJsSoMiekLpm_95dgBoquqiWd5jwjG9CYuGEHh2F0dG5ldHOIAMAAAAAAAACGY2xpZW500YpMaWdodGhvdXNlhTcuMC4xhGV0aDKQB1JOe2AAADj__________4JpZIJ2NIJpcIQiCohihHF1aWOCIymJc2VjcDI1NmsxoQP2tooJWZ8X12lA2NzIS6jK4YVwXdmZae99q9_IPceVyohzeW5jbmV0cw-DdGNwgiMog3VkcIIjKA",
        "p2p_addresses": [
          "/ip4/34.10.136.98/tcp/9000/p2p/16Uiu2HAmVG45m3hxShsGJVhPQbPmz2roL1soSp3JakZoG4iPbLob"
        ],
        "discovery_addresses": [
          "/ip4/34.10.136.98/udp/9000/p2p/16Uiu2HAmVG45m3hxShsGJVhPQbPmz2roL1soSp3JakZoG4iPbLob"
        ],
        "metadata": {
          "seq_number": "6",
          "attnets": "0x00c0000000000000",
          "syncnets": "0x0f"
        }
      }
     }
     ```

## Deploy a participating node 
Now that we have deployed the initial nodes of the network we can deploy additional nodes onto the network. We'll use an already existing dev-net [uct_finhub-devnet-1](https://github.com/FinHubSA/uct_finhub-devnets/tree/main/network-configs/devnet-1) as an example.
1. To deploy a node that syncs to an existing network we will add some parameters to the network_params.yaml file
    - `network:` -  This parameter will specify the dev network the nodes sync to.
      - The `devnet-1` in the network name is a key word that lets the [ethereum-package](https://github.com/ethpandaops/ethereum-package) know that the created nodes will synch to `devnet-1` of the `uct-finhub-devenets` repository.
        > Example: For the network: `verkle-gen-devnet-7` there is the github repository [verkle-gen-devnets](https://github.com/ethpandaops/verkle-devnets) from the ethpandaops github account.
        
        > There is also a `network-configs` folder which containes the [gen-devnet-7](https://github.com/ethpandaops/verkle-devnets/tree/master/network-configs/gen-devnet-7/metadata) metadata that the ethereum-package will use to bootstrap from and sync the created nodes to.
    - `devnet_repo:` - This parameter specifies which github account to search for to find the dev network specified by the `network` parameter.
      - The default account is [ethpandaops](https://github.com/ethpandaops) which runs the `verkle-gen-devnets`.
    - `nat_exit_ip:` - Comment this line out so that there are no conflicts with the initial nodes.
    - `checkpoint_sync_enabled:` - This is for the consensus node to sync up to a bootstrap node specified by the end-point `checkpoint_sync_url`.
    - `checkpoint_sync_url:` - URL for the consensus client that will be used for performing a checkpoint sync.
2. To deploy a node on our uct_finhub-devnet-1 network:
   - Remove the comment out the comments from the lines with this comment `** UNCOMMENT **`
   - Comment out any lines whihc have this comment at the end of the line `** COMMENT OUT **`
   - Then run the ethereum kurtosis package as below:
     ```bash
     kurtosis run github.com/ethpandaops/ethereum-package --args-file ./network_params.yaml --image-download always
     ```
3. To deploy to a new network:
   - Create a github repository that will contain the network-configs of the devnets you'll deploy e.g. my-private-devnets
   - Create folder in called `network-configs`
   - Create a folder for the dev network e.g. `devnet-1` and create a folder called `metadata` in the devnet-1 folder.
   - We need the genesis files from an existing network node. Run the command below to get these files:
     ```bash
     kurtosis files download alert-bay el_cl_genesis_data ~/Downloads
     ```
   - Look in the `Downloads` folder for the downloaded files. Copy the following files into the `metadata` folder created in the previous steps:
     - `chainspec.json`, `genesis_validators_root.txt`, `deposit_contract_block_hash.txt`, `genesis.json`, `config.yaml`, `deposit_contract.txt`, `bootstrap_nodes.txt`, `genesis.ssz`, `deposit_contract_block.txt`
    - Create an additional file called `enodes.txt`
    - In the `bootstap_nodes.txt` put in the enr of the consensus node. This is found by running the command for the `execution` node status in part 4 of the [Deploy a loadbalancer service](deploy-a-loadbalancer-service) section 
    - In the `enodes.txt` put in the enode ID of the consensus node. This is also found by running the command for the `consensus` node status in part 4 of the [Deploy a loadbalancer service](deploy-a-loadbalancer-service) section.
    - Commit and push all your changes to the main branch. The [UCT Finhub Devnets](https://github.com/FinHubSA/uct_finhub-devnets/tree/main) repository is an example.
      > Note: take a look at the `bootstap_nodes.txt` and the `enodes.txt` for an example of how they look
    - Then run the ethereum kurtosis package as below to deploy and sync the nodes to your network:
      ```bash
      kurtosis run github.com/ethpandaops/ethereum-package --args-file ./network_params.yaml --image-download always
      ```
     


