# Nginx Ingress Gateway

The `Ingress` is a Kubernets resource that allows to configure a HTTP Load Balancer for application running on Kubernetes, represented by one or more Services.

![Nginx](../../pictures/nginx.png)

## Adding Nginx Ingress on Azure
---

- `Create a Namespace`
```bash
kubectl create namespace nginx-ingress
```

- `Deploy Nginx Ingress Controller on Azure`
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace nginx-ingress \
    --set controller.replicaCount=2 \ # <-- Number of Nginx Controller a good number for production is 3
    # Below Configurations is Azure Specifics
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux
```
- `Getting Load Balancer Public Ip`
```bash
kubectl --namespace nginx-ingress get services -o wide -w nginx-ingress-ingress-nginx-controller

# NAME                                     TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                      AGE
# nginx-ingress-ingress-nginx-controller   LoadBalancer   10.0.20.186   40.76.165.44   80:32621/TCP,443:32640/TCP   2m18s
```

- `Testing the Nginx Ingress Gateway`

For now, there is any route configured, however it possible to make a request on the external-ip an check if nginx returns a 404 error.

```bash
curl http://40.76.165.44

# <html>
# <head><title>404 Not Found</title></head>
# <body>
# <center><h1>404 Not Found</h1></center>
# <hr><center>nginx</center>
# </body>
# </html>
```

## Configuring Applications
---

Lets configure two applications to use Nginx Ingress Gateway.

- `App1`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "Welcome to Azure Kubernetes Service (AKS)"
---
apiVersion: v1
kind: Service
metadata:
  name: app1  
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: app1

```

- `App2`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "AKS Ingress Demo"
---
apiVersion: v1
kind: Service
metadata:
  name: app2  
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: app2

```

- `Creating Ingress Route`

The ingress route should be create on the same namespace where the service was created.

```yaml
# Ingress to App1
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app1
  annotations:
    kubernetes.io/ingress.class: nginx # <-- Nginx Ingress Controller automatically detects this annotation
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true" # <-- Allow to use Regex for Managing Routing 
    nginx.ingress.kubernetes.io/rewrite-target: /$1 #<-- Rewrites the request with the first capture group
spec:
  rules:
  - http:
      paths:
      # Matches:
      # /app1
      # /app1/
      # /app1/something(*)
      # Rewrites to : /app1/ or /app1
      - path: /app1(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: app1 # <-- Redirects to service app1
            port:
              number: 80
      # Used to load frontend images
      # Ex: /static/acs.png
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: app1 # <-- Redirects to service app1
            port:
              number: 80
``` 

```yaml
# Ingress to App2
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app2
  annotations:
    kubernetes.io/ingress.class: nginx # <-- Nginx Ingress Controller automatically detects this annotation
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true" # <-- Allow to use Regex for Managing Routing 
    nginx.ingress.kubernetes.io/rewrite-target: /$1 #<-- Rewrites the request with the first capture group
spec:
  rules:
  - http:
      paths:
      # Matches:
      # /app2
      # /app2/
      # /app2/something(*)
      # Rewrites to : /app2/ or /app2
      - path: /app2(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: app2 # <-- Redirects to service app1
            port:
              number: 80
      # Used to load frontend images
      # Ex: /static/acs.png
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: app1 # <-- Redirects to service app1
            port:
              number: 80
```

It is important to notice, that when there are `multiple matches` on a specific route the precedence will be given first to the longest matching path. If two paths are still equally matched, precedence will be given to paths with an exact path type over prefix path type.

## References
---

- [`Installing Nginx on AKS`](https://docs.microsoft.com/en-us/azure/aks/ingress-basic)

- [`Installing Internal Nginx on AKS`](https://docs.microsoft.com/en-us/azure/aks/ingress-internal-ip)

- [`Nginx Helm`](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/)

- [`K8's Ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress/) 