global:
  scrape_interval: 30s
  evaluation_interval: 30s

scrape_configs:
  - job_name: 'redis-cloud'
    scrape_interval: 30s
    metrics_path: /
    scheme: https
    tls_config:
      insecure_skip_verify: true
    static_configs:
      - targets: ['${split(":", redis_endpoint)[0]}:8070']
    scrape_timeout: 30s