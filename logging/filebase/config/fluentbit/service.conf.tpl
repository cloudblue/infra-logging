[SERVICE]
    Flush 1
    Daemon Off
    Log_Level info
    
    storage.path  {{ .Values.logging.fluentd | get "buffer_path" "/mnt/fluent" }}/fluentbit-storage/flbstore/
    storage.sync  normal
    storage.checksum off
    storage.max_chunks_up 128
    storage.backlog.mem_limit 5M
    storage.metrics on

    Parsers_File parsers.conf
    Parsers_File custom_parsers.conf
    HTTP_Server On
    HTTP_Listen 0.0.0.0
    HTTP_Port 2020