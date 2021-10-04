### Filesystem
<store>
  @type file         
  path {{ .Values.logging.output_to_filesystem.filesystem_path }}/${namespace}/%Y/%m/%d/${podname}_${containername}
  compress gzip
  recompress true
  append true

  <format>
    @type single_value
    add_newline false
    message_key message
    newline lf    
  </format>
  
  # https://docs.fluentd.org/configuration/buffer-section
  <buffer namespace,time,podname,containername>
    @type file
    path {{ .Values.logging.fluentd | get "buffer_path" "/mnt/fluent" }}/fluentd-buffers/filesystem

    total_limit_size 20Gb

    timekey      1d  # chunks per 1day
    timekey_wait 30  # 30 sec delay for flush 
    timekey_use_utc true # use utc
    # flush_mode immediate
    flush_mode interval
    flush_interval 20
  </buffer>
</store>