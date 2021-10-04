#!/bin/sh

max_file_size=300000000000

log_dir=/app/logs
job_download=$log_dir/job_download
job_upload=$log_dir/job_upload
job_delete=$log_dir/job_delete

function init() {

    apk --update add --virtual build-dependencies --no-cache wget tar
    apk --update add libc6-compat ca-certificates coreutils

    mkdir /app
    cd /app

    wget -O azcopyv10.tar https://aka.ms/downloadazcopy-v10-linux
    tar -xf azcopyv10.tar

    VERSION=$(ls -d azcopy_linux*)
    echo $VERSION

    mv ${VERSION}/azcopy /app/azcopy
    chmod u+x /app/azcopy

    rm -rf azcopy_linux* azcopyv10.tar
    apk del build-dependencies

    mkdir /app/logs
    mkdir /app/merge

}

function Help() {
    # Display Help
    echo "Syntax: $0 -d DAY"
    echo
    echo "Options:"
    echo "  -d, --day  : Day to compress. Format: YYYYmmdd. Mandatory parameter."
    echo "  -h, --help : This help."
    echo
    echo "Examples: "
    echo "$0 -d 20210416"
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
    LogError $1
    echo
    Help
    exit
}

if [[ $# -eq 0 ]]; then
    Help
    exit
fi

# Parse args
while [[ $# -gt 0 ]]; do
    i="$1"
    case $i in

    -d | --date)
        DAY="$2"
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

if [ -z "$DAY" ]; then
    Error "DAY parameter not found."
fi

if [ -z "$SAS" ]; then
    Error "SAS env var not found."
fi

if [ -z "$URL" ]; then
    Error "URL env var not found."
fi

init

max_file_size_human=$(echo $max_file_size | numfmt --to=iec)
LogInfo "Start: DAY: $DAY max_file_size $max_file_size_human"

IFS=$'\x0A'$'\x0D'

LogInfo "Start Compressing"

for line in $(/app/azcopy list "$URL?$SAS" --machine-readable | grep "\.log" | grep -v "\.gz"); do

    info=$(echo $line | cut -d";" -f 1)
    file=$(echo $info | cut -d":" -f 2 | xargs)
    content_length=$(echo $line | cut -d";" -f 2)
    length=$(echo $content_length | cut -d":" -f 2 | xargs)
    length_human=$(echo $length | numfmt --to=iec)
    file_day=$(echo $file | cut -d"/" -f3)$(echo $file | cut -d"/" -f4)$(echo $file | cut -d"/" -f5)

    if [ "$file_day" -le "$DAY" ] && [ "$length" -le "$max_file_size" ]; then

        LogInfo "Processing $file file_day: $file_day size: $length_human"

        /app/azcopy copy "$URL/$file?$SAS" $log_dir --check-md5 FailIfDifferent --from-to=BlobLocal >$job_download

        if grep -q "Final Job Status: Completed" $job_download; then

            #LogInfo "$file download ok"
 
            LogInfo "   Compress and upload $file"
            gzip $log_dir/$(basename $file)

            /app/azcopy copy $log_dir/$(basename $file).gz "$URL/$file.gz?$SAS" --from-to LocalBlob >$job_upload

            if grep -q "Final Job Status: Completed" $job_upload; then

                LogInfo "   Deleting Blob File on Azure $file"
                /app/azcopy rm "$URL/$file?$SAS" >$job_delete

                if grep -q "Final Job Status: Completed" $job_delete; then
                    # LogInfo "$file delete done"
                    rm -f $log_dir/*
                else
                    LogError "   $file delete failed"
                fi
            else
                LogError "   $file upload failed"
            fi

        else
            LogError "downloading $file"
        fi
    else
        if [ "$length" -gt "$max_file_size" ]; then
            LogInfo "   Not Processing $file size: $length_human"
        fi
    fi

done

LogInfo "End Compressing"