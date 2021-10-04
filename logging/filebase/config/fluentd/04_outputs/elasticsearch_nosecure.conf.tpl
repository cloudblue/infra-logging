#### Elasticsearch output
<store>
    @id elasticsearch
    @type elasticsearch
    @log_level "info"


    log_es_400_reason true
    include_tag_key true
    host "elasticsearch-master"
    port "9200"
    path ""
    scheme "http"
    ssl_verify "false"
    ssl_version "TLSv1_2"
    type_name "_doc"
    logstash_format true
    logstash_prefix logstash-${es_index}
    reconnect_on_error true
    suppress_type_name true
    time_key event_time
    remove_keys es_index,filepath,message_k8s,elastic_key,event_time
    # id_key elastic_key

    <buffer es_index>
        @type file
        path {{ .Values.logging.fluentd | get "buffer_path" "/mnt/fluent" }}/fluentd-buffers/elasticsearch

        total_limit_size 20Gb

        flush_mode interval
        flush_thread_count 1
        flush_interval 10s

        retry_type exponential_backoff
        retry_forever false
        retry_max_interval 30
        retry_timeout 1h
        retry_max_times 50
        disable_chunk_backup true

        # Total size of the buffer (32MiB/chunk * 640 chunk) = 20G
        chunk_limit_size "32M"        
        queue_limit_length "640"
    </buffer>
    
</store>