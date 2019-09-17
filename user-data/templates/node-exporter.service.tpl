- content: |
    [Unit]
    Description=Node Exporter

    [Service]
    Type=simple
    Restart=on-failure
    ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory /var/lib/node_exporter/textfile_collector
    PIDFile=/var/run/node_exporter.pid
    ExecReload=/bin/kill -HUP $MAINPID
    [Install]
    WantedBy=multi-user.target
  path: ${service_type_path}
  permissions: '${file_permissions}'
