#!/bin/bash

log_dir=./log
job_download=$log_dir/job_download

function init() {

    cd /usr/share/logstash/bin

    curl -s https://azcopyvnext.azureedge.net/release20210616/azcopy_linux_amd64_10.11.0.tar.gz --output azcopyv10.tar
    tar -xf azcopyv10.tar

    VERSION=$(ls -d azcopy_linux*)
    echo $VERSION

    mv ${VERSION}/azcopy azcopy
    chmod u+x azcopy

}

function parse_yaml {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
        awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function Help() {
    # Display Help
    echo "Syntax: $0 -e ENVIRONMENT -n NAMESPACE -d DAY -f FILENAME"
    echo
    echo "Options:"
    echo "  -n, --namespace : Namespace to import. Mandatory parameter."
    echo "  -d, --day       : Day to import. Format: YYYY/mm/dd. Mandatory parameter."
    echo "  -f, --filename  : Filename to import. Mandatory parameter."
    echo "  -h, --help      : This help."
    echo
    echo "Examples: "
    echo "$0 -e masterdev-rep1 -n masterdev-rep1 -d 2021/07/25 -f bss-atm-7f64c66c85-w2gl9_atm_0.log.gz"
    echo
}

function get_time() {
    date -u +"%Y-%m-%d %T"
}

function LogInfo() {
    echo "$(get_time) INFO: $1"
}

function LogError() {
    echo "$(get_time) ERROR: $1"
}

function Error() {
    echo
    LogError "$1"
    echo
    Help
    exit
}

if ! command -v azcopy &>/dev/null; then
    Error "azcopy could not be found. Install from https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10"
fi

if [[ $# -eq 0 ]]; then
    Help
    exit
fi

# Parse args
while [[ $# -gt 0 ]]; do
    i="$1"
    case $i in
    -e | --environment)
        ENVIRONMENT="$2"
        shift 2
        ;;
    -n | --namespace)
        NAMESPACE="$2"
        shift 2
        ;;
    -d | --date)
        DAY="$2"
        shift 2
        ;;
    -f | --filename)
        FILENAME="$2"
        shift 2
        ;;

    -h | --help)
        Help
        exit
        ;;
    --)
        shift
        break
        ;;
    *)
        break
        ;;
    esac
done


jsonSecret=$(kubectl -n infrastructure get secret azure-storage-credentials -o jsonpath='{.data}')

SAS=$(echo $jsonSecret | jq .sas | tr -d '"' | base64 --decode )
URL=$(echo $jsonSecret | jq .url_blob_container | tr -d '"' | base64 --decode )

if [ -z "$NAMESPACE" ]; then
    Error "NAMESPACE parameter not found."
fi

if [ -z "$DAY" ]; then
    Error "DAY parameter not found."
fi

date "+%Y/%m/%d" -d "$DAY" >/dev/null 2>&1
is_valid=$?
if [ $is_valid == 1 ]; then
    Error "$DAY format is not valid, should be YYYY/mm/dd."
fi

if [ -z "$FILENAME" ]; then
    Error "FILENAME parameter not found."
fi

if [ -z "$SAS" ]; then
    Error "SAS env var not found."
fi

if [ -z "$URL" ]; then
    Error "URL env var not found."
fi

LogInfo "Start: DAY: $DAY FILENAME $FILENAME"

file="logs/$NAMESPACE/$DAY/$FILENAME"

LogInfo "Processing $URL/$file to $log_dir "

azcopy copy "$URL/$file?$SAS" $log_dir --check-md5 FailIfDifferent --from-to=BlobLocal >$job_download

if grep -q "Final Job Status: Completed" $job_download; then

    LogInfo "$log_dir/$FILENAME download ok, lets upload the file to logstash-logstash-0:/var/log/logstash/$NAMESPACE/$FILENAME"

    kubectl -n infrastructure exec --stdin --tty logstash-logstash-0 "--" sh -c "mkdir -p /var/log/logstash/$NAMESPACE"
    kubectl -n infrastructure cp "$log_dir/$FILENAME" logstash-logstash-0:/var/log/logstash/$ENVIRONMENT/$NAMESPACE/$FILENAME
    rm $log_dir/$FILENAME
    rm $job_download

else
    LogError "downloading $file"
fi

LogInfo "End"
