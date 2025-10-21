apiVersion: 1
datasources:
  - name: redis-cloud
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true