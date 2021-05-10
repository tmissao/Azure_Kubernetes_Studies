# FluentBit

FluentBit is a lightweight software developed by `FluentD` which the main goal is collect logs from many different system, such as `Kubernetes`. Sending the collected log from another destination, mainly `ElasticSearch`.

## Installing Elasticsearch
---

- `Running as a Service` - https://info.elastic.co/elasticsearch-service-trial-course.html

## Installing FluentBit
---

- `Create a Custom Values.yaml File`
```yaml
# custom-values.yaml
config:
  outputs: |
    [OUTPUT]
        Name es
        Match *
        Host <es-cluster-endpoint>
        Port <es-cluster-port>
        Cloud_Auth <es-cluster-username:password>
        Index kubernets-logs
        TLS On
        Retry_Limit False
```

- `Installing FluentBit`

```bash

kubectl create ns logging

helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
helm install fluent-bit fluent/fluent-bit \
  -f ./custom-values.yaml -n logging
```

- `Retrieving Log on ElasticSearch`
```bash
curl -XGET -u <es-cluster-username>:<es-cluster-password> <es-cluster-endpoint>/kubernets-logs/_search\?pretty\=true

{
  "took" : 4,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 2544,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "kubernets-logs",
        "_type" : "_doc",
        "_id" : "twNCVnkBnBjSjIOhHze-",
        "_score" : 1.0,
        "_source" : {
          "@timestamp" : "2021-05-10T12:30:43.841Z",
          "log" : "2021-05-10T12:30:43.841439356Z stdout F INF: Tunnel front and end both server.version == local.version, no rotation needed",
          "kubernetes" : {
            "pod_name" : "tunnelfront-6dd4666976-bvcrb",
            "namespace_name" : "kube-system",
            "pod_id" : "4836ac9d-3631-4853-8a64-8914edb24a53",
            "labels" : {
              "component" : "tunnel",
              "pod-template-hash" : "6dd4666976"
            },
            "host" : "aks-default-41057252-vmss000001",
            "container_name" : "tunnel-front",
            "docker_id" : "c04a5c40b33409b8efbb9215897d5f18e77029c2b8fe1a10f71782ac9fbe8736",
            "container_hash" : "sha256:7bb1a6df937ab53db9daadb5daeaec136e628f333e77d8e6d9bef34ed69ca7ab",
            "container_image" : "mcr.microsoft.com/aks/hcp/hcp-tunnel-front:master.0326.5"
          }
        }
      },
      {
        "_index" : "kubernets-logs",
        "_type" : "_doc",
        "_id" : "uANCVnkBnBjSjIOhHze-",
        "_score" : 1.0,
        "_source" : {
          "@timestamp" : "2021-05-10T12:30:43.847Z",
          "log" : "2021-05-10T12:30:43.847480416Z stdout F INF: Ssh to tunnelEnd is connected with pid: 186",
          "kubernetes" : {
            "pod_name" : "tunnelfront-6dd4666976-bvcrb",
            "namespace_name" : "kube-system",
            "pod_id" : "4836ac9d-3631-4853-8a64-8914edb24a53",
            "labels" : {
              "component" : "tunnel",
              "pod-template-hash" : "6dd4666976"
            },
            "host" : "aks-default-41057252-vmss000001",
            "container_name" : "tunnel-front",
            "docker_id" : "c04a5c40b33409b8efbb9215897d5f18e77029c2b8fe1a10f71782ac9fbe8736",
            "container_hash" : "sha256:7bb1a6df937ab53db9daadb5daeaec136e628f333e77d8e6d9bef34ed69ca7ab",
            "container_image" : "mcr.microsoft.com/aks/hcp/hcp-tunnel-front:master.0326.5"
          }
        }
      }
      ...
    ]
  }
}
```

## References
---

- [`FluentBit`](https://docs.fluentbit.io/manual/)

- [`FluentBit Kubernetes`](https://docs.fluentbit.io/manual/installation/kubernetes)

- [`FluentBit to ElastiSearch`](https://docs.fluentbit.io/manual/pipeline/outputs/elasticsearch#fluent-bit-elastic-cloud)