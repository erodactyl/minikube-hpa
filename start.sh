#!/bin/bash

# Exit on any error
set -e

echo "Starting Kubernetes setup script..."

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Error: minikube is not installed"
    exit 1
fi

# Check if docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running"
    exit 1
fi

# Start minikube if it's not already running
if ! minikube status &> /dev/null; then
    echo "Starting minikube..."
    minikube start
else
    echo "Minikube is already running"
fi

# Enable required addons
echo "Enabling ingress addon..."
minikube addons enable ingress

echo "Enabling metrics-server addon..."
minikube addons enable metrics-server

# Wait for metrics-server deployment to be ready
echo "Waiting for metrics-server to be ready..."
kubectl wait --for=condition=available deployment metrics-server -n kube-system --timeout=120s

# Update metrics-server configuration
echo "Updating metrics-server configuration..."
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--cert-dir=/tmp", "--secure-port=4443", "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname", "--kubelet-use-node-status-port", "--metric-resolution=15s", "--kubelet-insecure-tls"]}]'

# Update /etc/hosts
echo "Updating /etc/hosts..."
if ! grep -q "helloworld.local" /etc/hosts; then
    echo "Adding helloworld.local to /etc/hosts..."
    echo "127.0.0.1 helloworld.local" | sudo tee -a /etc/hosts
else
    echo "helloworld.local already exists in /etc/hosts"
fi

# Set docker env to use minikube's docker daemon
echo "Setting up docker environment..."
eval $(minikube docker-env)

# Build the Docker image
echo "Building Docker image..."
docker build -t node-helloworld .

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f kube/deployment.yaml -f kube/hpa.yaml -f kube/ingress.yaml -f kube/service.yaml

# Check if hey is installed
if ! command -v hey &> /dev/null; then
    echo "Installing hey load testing tool..."
    brew install hey
fi


echo "Setup complete! You can now access the application at http://helloworld.local"
echo "To run a load test, use: hey http://helloworld.local/expensive"
echo "To monitor the cluster, install k9s and run: k9s"

# Start minikube tunnel
echo "Starting minikube tunnel..."
pkill -f "minikube tunnel" || true  # Kill any existing tunnel
sudo minikube tunnel

