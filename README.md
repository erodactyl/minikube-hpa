# Minimal local Kubernetes setup

1. minikube start

2. eval $(minikube docker-env)

3. docker build -t node-helloworld .

4. minikube addons enable ingress

5. minikube addons enable ingress-dns

6. minikube addons enable metrics-server

7. kubectl apply -f all files under kube/ directory

8. Append 127.0.0.1 helloworld.local to /etc/hosts

9. minikube tunnel
