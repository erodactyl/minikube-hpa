# Minimal local Kubernetes setup

This documentation assumes you are using a local Kubernetes tool called Minikube. Minikube runs inside a Docker container on a local machine. To install Minikube on MacOS, follow [this guide](https://minikube.sigs.k8s.io/docs/start/).

Make sure to also have Docker installed and running on your machine, and the kubectl command-line tool configured to communicate with your cluster.

To run the Horizontal Pod Autoscaling test we need to create the cluster.

```bash
minikube start
```

We then need to enable a few addons. Namely - `ingress` and `metrics-server`.

An Ingress is an object which allows external access to a service in the cluster.
To enable the NGINX Ingress controller, run the following command:

```bash
minikube addons enable ingress
```

To make sure the HPA works correctly, it needs to have access to metrics about the pods. For this we need to enable a metrics server. Minikube makes this easy as well.

```bash
minikube addons enable metrics-server
```

By default the `metrics-server` reports every 60 seconds. This is not ideal for bursty workflows that need to scale up quickly. We can change this by running:

```bash
kubectl edit deployment metrics-server -n kube-system
```

Here we can change the `metric-resolution` argument passed to the container to 15s, like so:

```yaml
spec:
  containers:
    - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
```

There are multiple ways of sending requests to the cluster running inside of Minikube. One of the simplest ways is to add the entry `127.0.0.1 helloworld.local` to /etc/hosts. Then we can run `minikube tunnel`, and we have all the pieces configured to test the HPA.

Now, let's build the Docker container in the context of the minikube cluster, so that it has access to it.

```bash
eval $(minikube docker-env)
docker build -t node-helloworld .
```

To deploy all the Kubernetes manifests, run:

```bash
kubectl apply -f kube/deployment.yaml -f kube/hpa.yaml -f kube/ingress.yaml -f kube/service.yaml
```

### Load testing

There are multiple methods to watch the cluster while load testing. We can look at the logs or at the HPA events by running `kubectl describe hpa`. Another way using a GUI is to use a tool called [k9s](https://k9scli.io/), with which we can visually see new pods getting created, or old ones be destroyed. Simply run `k9s`.

For load testing we can use an open source tool called [hey](https://github.com/rakyll/hey).

```bash
brew install hey
```

Run:

```bash
hey http://helloworld.local/expensive
```

The route `/expensive` calculates the fibonacci of 35, which is a CPU-intensive operation. With the setup of the `kube/deployment`, the autoscaling works but still isn't able to handle all 200 requests. This can easily be fixed in a production environment by giving more resources to the pods. In this particular case, every pod has a limit of 0.2 CPUs. As the default Minikube setup has access to 2 CPUs, this is the maximum we can have for 10 pods.

Every 15 seconds the metrics-server reports the CPU of the running pods, and the HPA uses that to calculate the new desired number of pods. After the requests end, there is 1 minute of "stabilization window". After this, if downscaling is still required according to the HPA, the unneded pods will go down.
