# Prometheus

Prometheus is the mainly tool used to monitoring highly dynamic container environments, such as: `Kubernetes` and `Swarm`.

## Installing Prometheus
---

```bash
# Creates Namespace
kubectl create ns monitoring

# Add Helm Repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Installing Prometheus Stack
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Getting Prometheus Stack Pods
kubectl get pods -n monitoring

# NAME                                                     READY   STATUS    RESTARTS   AGE
# alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          42s
# prometheus-grafana-6549f869b5-c55rr                      2/2     Running   0          52s
# prometheus-kube-prometheus-operator-f5d67844f-dbp4t      1/1     Running   0          52s
# prometheus-kube-state-metrics-685b975bb7-spjss           1/1     Running   0          52s
# prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   1          42s
# prometheus-prometheus-node-exporter-tdw44                1/1     Running   0          53s
# prometheus-prometheus-node-exporter-z56bl                1/1     Running   0          53s
``` 

## Adding Istio Grafana Dashboards

If grafana sidecar is enable, it is possible to add new dashboards using specific labels on `Config Map`. By default prometheus-stack enables sidecar on grafana deployment and this sidecar searches by configmaps with the label `grafana_dashboard`

```yaml
granafa:
# ...
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
```

Thus, to add a new dashboard just is necessary to add the required label, like 
```yaml
# dashboard/istio-dashboards.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: istio-grafana-dashboards
  labels:
    grafana_dashboard: grafana_dashboard
data:
  istio-performance-dashboard.json: |
    ...
  pilot-dashboard.json: |
    ...
```

The deployment [istio-dashboard](./dashboard/istio-dashboards.yaml) was extracted from `addons/grafana.yaml` in istio operator files.

- `Adding Istio Dashboards`
```bash
kubectl apply -f dashboard/istio-dashboards.yaml -n monitoring

# To Quickly Load the dashboards just restart the grafana pods.

kubectl rollout restart deployment prometheus-grafana -n monitoring
```

## Exporting Istio Metrics
---
To allowing Prometheus to get data from Istio Components it is necessary to deploy a `Service Monitor`, this deploy could be find on istio operator files also, at `addons/extras/prometheus-operator.yaml`.

However it is necessary to change the labels `metadata.labels.release: istio` to `matadata.labels.release: prometheus`

```yaml
# ./istio-exporter/prometheus-operator.yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: envoy-stats-monitor
  namespace: istio-system
  labels:
    monitoring: istio-proxies
    release: prometheus
spec:
  selector:
    matchExpressions:
    - {key: istio-prometheus-ignore, operator: DoesNotExist}
  namespaceSelector:
    any: true
  jobLabel: envoy-stats
  podMetricsEndpoints:
  - path: /stats/prometheus
    interval: 15s
    relabelings:
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_container_name]
      regex: "istio-proxy"
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape]
    - sourceLabels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $1:$2
      targetLabel: __address__
    - action: labeldrop
      regex: "__meta_kubernetes_pod_label_(.+)"
    - sourceLabels: [__meta_kubernetes_namespace]
      action: replace
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      action: replace
      targetLabel: pod_name
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-component-monitor
  namespace: istio-system
  labels:
    monitoring: istio-components
    release: prometheus
spec:
  jobLabel: istio
  targetLabels: [app]
  selector:
    matchExpressions:
    - {key: istio, operator: In, values: [pilot]}
  namespaceSelector:
    any: true
  endpoints:
  - port: http-monitoring
    interval: 15s
```

## Deploying Demo
---

- `Installing Demo Application`
```bash
kubectl apply -f demo/1-label-default-namespace.yaml
kubectl apply -f demo/2-application-no-istio.yaml
kubectl apply -f demo/3-gateway.yaml
kubectl apply -f demo/4-circuit-breaking.yaml
```

- `Getting Istio Ingress Gateway Extenal IP`
```bash
kubectl get svc istio-ingressgateway -n istio-system
# NAME                   TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                                                                      AGE
# istio-ingressgateway   LoadBalancer   10.0.20.121   52.226.45.34   15021:31854/TCP,80:30547/TCP,443:30877/TCP,15012:31308/TCP,15443:32143/TCP   8m28s
```

- `Accessing the Demo`
```bash
curl -s http://52.226.45.34 -v
```

## Accessing Istio Metrics
---

```bash
kubectl -n monitoring port-forward  svc/prometheus-grafana 3000
```

## References

- [`Prometheus Stack`](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

- [`Grafana`](https://github.com/grafana/helm-charts/tree/main/charts/grafana#grafana-helm-chart)

- [`Grafana Password`](https://dev.to/irisroques/how-to-get-grafana-password-kube-stack-prometheus-41e0s)

- [`Istio Installer Prometheus Operator`](https://github.com/istio/installer/tree/master/istio-telemetry/prometheus-operator)