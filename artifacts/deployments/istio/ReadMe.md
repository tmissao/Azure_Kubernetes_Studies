# Istio on AKS

## Configuring Istio
---

- `Installing Istio`

```bash
istioctl install
```

- `Installing Istio Addons`
```bash
kubectl apply -f ./addons
```

- `Getting Istio Ingress Gateway Extenal IP`
```bash
kubectl get svc istio-ingressgateway -n istio-system
# NAME                   TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                                                                      AGE
# istio-ingressgateway   LoadBalancer   10.0.20.121   52.226.45.34   15021:31854/TCP,80:30547/TCP,443:30877/TCP,15012:31308/TCP,15443:32143/TCP   8m28s
```

- `Configure the Custom Domain Name`
Create a DNS A Record point to nginx-loadbalancer

|HOST |DNS RECORD | VALUE
:--- | :---: | ---
|istio.codefeeling.com.br|A|52.226.45.34

<br/>

- `Installing Demo Application`
```bash
kubectl apply -f demo/1-label-default-namespace.yaml
kubectl apply -f demo/2-application-no-istio.yaml
kubectl apply -f demo/3-gateway.yaml
kubectl apply -f demo/4-circuit-breaking.yaml
```


- `Allowing Just HostName Access to the Demo`
```yaml
# Edit this file: gateway.yaml
# demo/gateway.yaml
#
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ingress-gateway-configuration
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - istio.codefeeling.com.br   # <-- Add your Host name here
---
# All traffic routed to the fleetman-webapp service
kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: fleetman-webapp
  namespace: default
spec:
  hosts:
    - istio.codefeeling.com.br # <-- Add your Host name here
    - fleetman-webapp.default.svc.cluster.local
  gateways:
    - ingress-gateway-configuration
  http:
    - route:
      - destination:
          host: fleetman-webapp

```

- `Accessing the Demo`
```bash
curl -s http://istio.codefeeling.com.br | grep title
# <title>Fleet Management</title>

# Since the Gateway Hostname was configure it is impossible to access the demo using direct the loadbalancer external IP

curl -s http://52.226.45.34 -v
# *   Trying 52.226.45.34:80...
# * TCP_NODELAY set
# * Connected to 52.226.45.34 (52.226.45.34) port 80 (#0)
# > GET / HTTP/1.1
# > Host: 52.226.45.34
# > User-Agent: curl/7.68.0
# > Accept: */*
# > 
# * Mark bundle as not supporting multiuse
# < HTTP/1.1 404 Not Found
# < date: Sat, 08 May 2021 13:55:01 GMT
# < server: istio-envoy
# < content-length: 0
# < 
# * Connection #0 to host 52.226.45.34 left intact

```

- `Accessing Kiali`
```bash
kubectl -n istio-system port-forward  svc/kiali  20001:20001
curl -s http://localhost:20001
```

## Configuring SSL
---

- `Installing Cert Manager`
```bash
# Creates Namespace
kubectl create namespace cert-manager

# Add Cert Manager Helm Repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Installing Cert Manager
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.3.1 \
  --set installCRDs=true
```

- `Creating Cluster Issuer`

A Cluster Issue represents a certificate authority from which signed x509 certificates can be obtained, such as Let's Encrypt.

The Cluster Issue resource is a single issuer that can be consumed by multiple namespaces.

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: t.missao@gmail.com # <-- Add your email here
    privateKeySecretRef:
      name: letsencrypt
    solvers:
      - http01:
          ingress:
            class: istio
```

- `Creating Istio SSL Certificate`

The certificate should be created in the same namespace as the `istio-ingressgateway`

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: ingress-cert
  namespace: istio-system
spec:
  secretName: ingress-cert
  commonName: istio.codefeeling.com.br # <-- Add Your HostName here
  dnsNames:
  -  istio.codefeeling.com.br # <-- Add Your HostName here
  issuerRef:
    name: letsencrypt # <-- ClusterIssuer Name
    kind: ClusterIssuer
    group: cert-manager.io
```

- `Updating Istio Gateway to use SSL`
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ingress-gateway-configuration
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    tls:
      httpsRedirect: true # <-- Redirects HTTP to HTTPS
    hosts:
    - istio.codefeeling.com.br
  - port:
      number: 443 # <-- Just allow traffic on port 443
      name: https
      protocol: HTTPS # <-- Just allow protocol HTTPS
    tls: # <-- Configures SSL
      mode: SIMPLE
      credentialName: ingress-cert # <-- Certificate Name
    hosts:
    - istio.codefeeling.com.br   # <-- Add your Host name here
```

>Now the Demo App can handle SSL connections ! 


## References
---

- [`Istio Cert-Manager Integration`](https://istio.io/latest/docs/ops/integrations/certmanager/)

- [`Cert Manager`](https://cert-manager.io/docs/usage/certificate/)

- [`Istio with Https Traffic`](https://medium.com/intelligentmachines/istio-https-traffic-secure-your-service-mesh-using-ssl-certificate-ac20ec2b6cd6)
