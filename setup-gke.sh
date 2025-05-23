#!/bin/bash

# === CONFIGURATION ===
PROJECT_ID="ethereum-test-network"
BILLING_ACCOUNT_ID="0162E1-2DD205-117CC2"  # e.g. 012345-6789AB-CDEF01
REGION="us-central1"
ZONE="us-central1-c"
CLUSTER_NAME="ethereum-cluster"
LOADBALANCER_IP_NAME="el-loadbalancer-ip"

# === 1. Create GCP Project ===
if gcloud projects describe "$PROJECT_ID" &> /dev/null; then
  echo "✅ Project '$PROJECT_ID' already exists."
else
  echo "🚀 Creating project '$PROJECT_ID'..."
  gcloud projects create "$PROJECT_ID" --name="Ethereum Test Network"
fi

# Set it as the active project
gcloud config set project $PROJECT_ID

# === 2. Link Billing Account ===
echo "💳 Linking billing account..."
gcloud beta billing projects link $PROJECT_ID \
  --billing-account=$BILLING_ACCOUNT_ID

# === 3. Enable Required APIs ===
echo "🚀 Enabling required services..."
gcloud services enable artifactregistry.googleapis.com
gcloud services enable container.googleapis.com

# === 4. Create Standard GKE Cluster ===
if gcloud container clusters describe "$CLUSTER_NAME" --zone "$ZONE" &> /dev/null; then
  echo "✅ GKE cluster '$CLUSTER_NAME' already exists in zone '$ZONE'."
else
  echo "🚀 Creating GKE cluster '$CLUSTER_NAME'..."
  gcloud container clusters create "$CLUSTER_NAME" \
    --zone "$ZONE" \
    --num-nodes=3 \
    --enable-ip-alias \
    --release-channel "regular" \
    --machine-type "e2-standard-2"
fi

# === 5. Get credentials for kubectl ===
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# === 6. Create a static IP address for the loadbalancer ===
echo "🚀 Creating static ip for loadbalancer..."

if gcloud compute addresses describe $LOADBALANCER_IP_NAME --region="$REGION" &> /dev/null; then
    echo "✅ loadbalancer IP $LOADBALANCER_IP_NAME already exists in region '$REGION'."
else
    gcloud compute addresses create $LOADBALANCER_IP_NAME \
    --region="$REGION" \
    --project="$PROJECT_ID"
fi

echo "⚙️ el loadbalancer IP address:"
gcloud compute addresses describe $LOADBALANCER_IP_NAME \
  --region="$REGION" \
  --format="get(address)"

echo "✅ GKE cluster '$CLUSTER_NAME' is ready in project '$PROJECT_ID'"
