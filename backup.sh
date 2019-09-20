#!/bin/bash

if [ -z $NEO4J_HOST ] ; then
    echo "You must specify a NEO4J_HOST env var"
    exit 1
fi
if [ -z $NEO4J_PORT ] ; then
    echo "You must specify a NEO4J_PORT env var"
    exit 1
fi

if [ -z $GCS_BUCKET_NEO4J ]; then
    echo "You must specify a google cloud storage GCS_BUCKET_NEO4J address such as gs://my-backups/"
    exit 1
fi

if [ -z $BACKUP_NAME ]; then
    BACKUP_NAME=graph.db
fi

CURRENT_DATE=$(date -u +"%Y-%m-%dT%H%M%SZ")
BACKUP_SET="$BACKUP_NAME-$CURRENT_DATE"

echo "Activating google credentials before beginning"
gcloud auth activate-service-account --key-file "$GOOGLE_APPLICATION_CREDENTIALS"

if [ $? -ne 0 ] ; then
    echo "Credentials failed; no way to copy to google."
    echo "Ensure GOOGLE_APPLICATION_CREDENTIALS is appropriately set."
fi

echo "=============== NEO4J Backup ==============================="
echo "Beginning backup from $NEO4J_HOST to /backup/$BACKUP_SET"
echo "To google storage bucket $GCS_BUCKET_NEO4J using credentials located at $GOOGLE_APPLICATION_CREDENTIALS"
echo "============================================================"

neo4j-admin backup --backup-dir="/backup/$BACKUP_SET" --name=graph.db-backup --from="$NEO4J_HOST:$NEO4J_PORT" --protocol=catchup

echo "Backup size:"
du -hs "/backup/$BACKUP_SET"

echo "Tarring -> /backup/$BACKUP_SET.tar"
tar -cvfz "/backup/$BACKUP_SET.tar.gz" "/backup/$BACKUP_SET"

echo "Zipped backup size:"
du -hs "/backup/$BACKUP_SET.tar.gz"

echo "Pushing /backup/$BACKUP_SET.tar.gz -> $GCS_BUCKET_NEO4J"
gsutil cp "/backup/$BACKUP_SET.tar.gz" "$GCS_BUCKET_NEO4J"

echo "Neo4j backups ended"
exit $?
