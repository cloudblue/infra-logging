# Import Storage Blob into Elasticsearch

Here you will find an utility to import Storage Blob files into Elasticsearch

## Logstash

To upload the data the script will upload the files into logstash, running on the kubernetes cluster where we have elasticsearch, and after it logstash will ingest the file data into elasticsearch.

### Install

To install logstash simply execute:

```bash
helm install logstash elastic/logstash -f logstash-values.yaml -n infrastructure

 ```

## Import

To upload the file simply use Azure Storage Explorer, and find the file you want to import.

We basically need the file name and path. Remember that the path is composed by NAMESPACE/YEAR/MONTH/DAY/filename

With this information now we can execute the script.

As a precondition you should install [azcopy](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) on your computer.

Also you need to pass the environment name, that basically is the filename of one of the files you will find on the root folder of the project ( masterdev-rep1, masterdev ... )

Example:

```bash
./import.sh -e masterdev-rep1 -n masterdev-rep1 -d 2021/07/25 -f bss-atm-7f64c66c85-w2gl9_atm_0.log.gz
``` 

## Index template

It could be a good idea to set a index template to set up the imported index with just one replica.

To do it just execute

```bash
PUT /_index_template/logstash-imported
{
    "index_patterns" : [
        "logstash-imported*"
    ],
    "template" : {
        "settings" : {
            "index" : {
                "priority" : "1",
                "number_of_replicas" : "0"
            }
        }
    }
}
```

## Check if the log was imported

Under /var/log/logstash/completed we will have the list of files that where imported, so if the file we want to import apperars here it means the logs where imported.

A suggested command to check could be: 

```bash
kubectl -n infrastructure exec --stdin --tty logstash-logstash-0 "--" sh -c "cat /var/log/logstash/completed"
```