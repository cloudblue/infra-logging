#### Azure blob storage output
<store>
  @type azure-storage-append-blob

  azure_storage_account             "#{ENV['AZURE_STORAGE_ACCOUNT']}"
  azure_storage_access_key          "#{ENV['AZURE_STORAGE_ACCESS_KEY']}"
  
  azure_container                   {{ .Values.logging.output_to_azurestorage.azure_container }}
  auto_create_container             true
  path                              {{ .Values.logging.output_to_azurestorage.azure_container_path }}/${namespace}/%Y/%m/%d/${podname}_${containername}
  # %{index} is used only if your blob exceed Azure 50000 blocks limit per blob to prevent data loss.  Maximum size of an append blob	50,000 x 4 MiB (approximately 195 GiB) https://docs.microsoft.com/en-us/azure/storage/blobs/scalability-targets
  azure_object_key_format           %{path}_%{index}.log
  time_slice_format                 %Y%m%d

  <format>
    @type single_value
    add_newline {{ .Values.logging.output_to_azurestorage.add_newline }}
    message_key message_k8s
    newline lf    
  </format>

  <buffer namespace,time,podname,containername>
    @type file
    path {{ .Values.logging.fluentd | get "buffer_path" "/mnt/fluent" }}/fluentd-buffers/azure_storage_append_blob

    total_limit_size 20Gb

    flush_mode interval
    flush_thread_count 1
    flush_interval 30s
    
    retry_forever true
    retry_type exponential_backoff
    retry_max_interval 30

    # Total size of the buffer (256MiB/chunk * 16 chunk) = 8G
    chunk_limit_size "128M"        
    queue_limit_length "16"

    overflow_action throw_exception
  </buffer>
</store>