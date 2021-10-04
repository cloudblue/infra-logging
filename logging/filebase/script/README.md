# Script

The fluentd output doesn't allow the creation of compress files on blob storage.

In order to save space, money and transfer time everyday we compress the logs files from the previous day.

Also with this operation we transform the blob file type from [Append to Block](https://docs.microsoft.com/en-us/rest/api/storageservices/understanding-block-blobs--append-blobs--and-page-blobs). This allows also to set up the [lifecycle management](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-lifecycle-management-concepts?tabs=azure-portal).

## Compress 

This is a bash script that uses [azcopy](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) to download an upload the files.

Basically what it does is:

- for each file not compressed
  - download it
  - compress it
  - upload it
  - if upload is successful 
    - delete not compressed file on blob storage
