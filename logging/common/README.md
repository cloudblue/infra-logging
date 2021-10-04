# Common

We use the following helm charts in both scenarios:

## Filestat

This helm chart is used just for monitoring purpose, in order to track the growth of the different logs files on each kubernetes node.

Project: https://github.com/michael-doubez/filestat_exporter

## Helm-cronjobs

This helm chart is used to set up cronjobs needed on both scenarios.

On-premises we need it to set up the retention policy.

On Azure cloud we need it to set up the compression.

Project: https://github.com/bambash/helm-cronjobs

