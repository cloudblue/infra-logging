
# Perf test

In this folder you will find two ways to execute performance test for logging

The idea is to generate logs to understand the behaviour of the solution.

## Flog

### URL 

https://github.com/mingrammer/flog

### How to execute the test

To delete previous executions:

```bash
./flog.sh delete
```
To execute the test you need to pass the work *apply* and the number of parallelism, so the number of pods that will be created:
```bash
./flog.sh apply 3
```

By default we will send 4,000,000 of logs with a delay between logs of .0005ms. 

If needed you can change this values directly on the script.

Hint: *1 sec == 1000 ms*
### Flog command line
 
```console
  -f, --format string      log format. available formats:
                           - apache_common (default)
                           - apache_combined
                           - apache_error
                           - rfc3164
                           - rfc5424
                           - json
  -o, --output string      output filename. Path-like is allowed. (default "generated.log")
  -t, --type string        log output type. available types:
                           - stdout (default)
                           - log
                           - gz
  -n, --number integer     number of lines to generate.
  -b, --bytes integer      size of logs to generate (in bytes).
                           "bytes" will be ignored when "number" is set.
  -s, --sleep duration     fix creation time interval for each log (default unit "seconds"). It does not actually sleep.
                           examples: 10, 20ms, 5s, 1m
  -d, --delay duration     delay log generation speed (default unit "seconds").
                           examples: 10, 20ms, 5s, 1m
  -p, --split-by integer   set the maximum number of lines or maximum size in bytes of a log file.
                           with "number" option, the logs will be split whenever the maximum number of lines is reached.
                           with "byte" option, the logs will be split whenever the maximum size in bytes is reached.
  -w, --overwrite          overwrite the existing log files.
  -l, --loop               loop output forever until killed.
```

## Banzai log-generator

### URL

https://banzaicloud.com/blog/logging-operator-monitoring/

https://github.com/banzaicloud/logging-operator

https://artifacthub.io/packages/helm/banzaicloud-stable/log-generator

### How to execute the test

```bash
helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com

helm uninstall log-generator -n infrastructure ; helm install log-generator -n infrastructure banzaicloud-stable/log-generator --version 0.1.5 -f ./log-generator.yaml
```

Usage of :
```console
  -byte-per-sec int
    	The amount of bytes to emit/s (default 200)
  -count int
    	The amount of log message to emit.
  -event-per-sec int
    	The amount of log message to emit/s (default 2)
  -metrics.addr string
    	Metrics server listen address (default ":11000")
  -randomise
    	Randomise log content (default true)
```

There are two important (and mutually exclusive) options:

- the byte-per-sec calculates the rate of event sending based on average log size
- the event-per-sec sets the event sending rate

 