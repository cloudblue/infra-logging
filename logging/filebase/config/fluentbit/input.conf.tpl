[INPUT]
    Name tail
    Tag kube.*

    Parser docker

    Buffer_Chunk_Size 2MB
    Buffer_Max_Size 100MB

    Path /var/log/containers/*.log
    Exclude_Path /var/log/containers/filestat*.log,/var/log/containers/fluent*.log

    Path_Key filepath

    Read_from_Head true

    Refresh_Interval 2

    Rotate_Wait 60

    Ignore_Older 24h

    Skip_Long_Lines On

    DB.sync normal
    DB.locking false
    DB.journal_mode WAL
    DB {{ .Values.logging.fluentd | get "buffer_path" "/mnt/fluent" }}/fluentbit-logs.db
    
    Mem_Buf_Limit 10m

    storage.type filesystem

    