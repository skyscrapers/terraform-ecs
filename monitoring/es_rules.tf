locals {
  elasticsearch_rules = <<EOF
  - alert: ElasticsearchClusterEndpointDown
    expr: elasticsearch_cluster_health_up{job="elasticsearch-exporter"} != 1
    for: 5m
    labels:
      severity: critical
      group: persistence
    annotations:
      description: 'Elasticsearch cluster endpoint for {{`{{ $labels.cluster }}`}} is DOWN!'
      summary: Elasticsearch cluster endpoint is DOWN!
      runbook_url: 'https://github.com/skyscrapers/documentation/tree/master/runbook.md#alert-name-elasticsearchclusterendpointdown'
  - alert: ElasticsearchHeapTooHigh
    expr: elasticsearch_jvm_memory_used_bytes{area="heap", job="elasticsearch-exporter"} / elasticsearch_jvm_memory_max_bytes{area="heap", job="elasticsearch-exporter"} > 0.9
    for: 15m
    labels:
      severity: warning
      group: persistence
    annotations:
      description: 'The JVM heap usage for Elasticsearch cluster {{`{{ $labels.cluster }}`}} on node {{`{{ $labels.node }}`}} has been over 90% for 15m'
      summary: ElasticSearch heap usage is high
      runbook_url: 'https://github.com/skyscrapers/documentation/tree/master/runbook.md#alert-name-elasticsearchheaptoohigh'

EOF

  elasticsearch_aws_rules = <<EOF
  - alert: ElasticsearchCloudwatchExporterDown
    expr: up{job="cloudwatch" != 1
    for: 5m
    labels:
      severity: critical
      group: persistence
    annotations:
      description: 'The Elasticsearch Cloudwatch metrics exporter for {{`{{ $labels.job }}`}} is down!'
      summary: Elasticsearch monitoring is DOWN!
      runbook_url: 'https://github.com/skyscrapers/documentation/tree/master/runbook.md#alert-name-elasticsearchcloudwatchexporterdown'
  - alert: ElasticsearchAWSLowDiskSpace
    expr: sum(label_join(aws_es_free_storage_space_minimum{job="cloudwatch, "cluster", ":", "client_id", "domain_name")) by (cluster) / min(clamp_max(elasticsearch_filesystem_data_size_bytes{job="elasticsearch-exporter", es_data_node="true"}/1024/1024, 102400)) by (cluster) <= 0.1
    for: 15m
    labels:
      severity: warning
      group: persistence
    annotations:
      description: 'AWS Elasticsearch cluster {{`{{ $labels.cluster }}`}} is low on free disk space'
      summary: AWS Elasticsearch low disk
      runbook_url: 'https://github.com/skyscrapers/documentation/tree/master/runbook.md#alert-name-elasticsearchawslowdiskspace'
  - alert: ElasticsearchAWSNoDiskSpace
    expr: sum(label_join(aws_es_free_storage_space_minimum{job="cloudwatch"}, "cluster", ":", "client_id", "domain_name")) by (cluster) / min(clamp_max(elasticsearch_filesystem_data_size_bytes{job="elasticsearch-exporter", es_data_node="true"}/1024/1024, 102400)) by (cluster) <= 0.05
    for: 15m
    labels:
      severity: critical
      group: persistence
    annotations:
      description: 'AWS Elasticsearch cluster {{`{{ $labels.cluster }}`}} has no free disk space'
      summary: AWS Elasticsearch out of disk
      runbook_url: 'https://github.com/skyscrapers/documentation/tree/master/runbook.md#alert-name-elasticsearchawsnodiskspace'

EOF

  elasticsearch_nonaws_rules = <<EOF
  - alert: ElasticsearchLowDiskSpace
    expr: elasticsearch_filesystem_data_available_bytes{job="elasticsearch-exporter"} / elasticsearch_filesystem_data_size_bytes{job="elasticsearch-exporter"} <= 0.1
    for: 15m
    labels:
      severity: warning
      group: persistence
    annotations:
      description: 'Elasticsearch node {{`{{ $labels.node }}`}} on cluster {{`{{ $labels.cluster }}`}} is low on free disk space'
      summary: Elasticsearch low disk
      runbook_url: 'https://github.com/skyscrapers/documentation/tree/master/runbook.md#alert-name-elasticsearchlowdiskspace'
  - alert: ElasticsearchNoDiskSpace
    expr: elasticsearch_filesystem_data_available_bytes{job="elasticsearch-exporter"} / elasticsearch_filesystem_data_size_bytes{job="elasticsearch-exporter"} <= 0.05
    for: 15m
    labels:
      severity: critical
      group: persistence
    annotations:
      description: 'Elasticsearch node {{`{{ $labels.node }}`}} on cluster {{`{{ $labels.cluster }}`}} has no free disk space'
      summary: Elasticsearch out of disk
      runbook_url: 'https://github.com/skyscrapers/documentation/tree/master/runbook.md#alert-name-elasticsearchnodiskspace'

EOF
}
