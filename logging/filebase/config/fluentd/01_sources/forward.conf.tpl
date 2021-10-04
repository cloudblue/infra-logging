<source>
    @type forward
    port 24224
    bind 0.0.0.0   
</source>

<system>
  workers {{ .Values.logging.fluentd | get "num_workers" "2" }}
</system>