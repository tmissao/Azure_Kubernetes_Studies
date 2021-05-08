# Istio on AKS

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