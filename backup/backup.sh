#!/bin/bash
set -e

if [ -z $NEO4J_POD ] ; then
    echo "You must specify a NEO4J_POD env var"
    exit 1
fi
if [ -z $NEO4J_NAMESPACE ] ; then
    echo "You must specify a NEO4J_NAMESPACE env var"
    exit 1
fi

if [ -z $GCS_BUCKET_NEO4J ]; then
    echo "You must specify a google cloud storage GCS_BUCKET_NEO4J address such as gs://my-backups/"
    exit 1
fi

if [ -z $BACKUP_NAME ]; then
    BACKUP_NAME=graph.db-single-node-backup
fi

CURRENT_DATE=$(date -u +"%Y-%m-%dT%H%M%SZ")
BACKUP_SET="$BACKUP_NAME-$CURRENT_DATE"
BACKUP_DIR="/var/lib/neo4j/backups"

echo "Activating google credentials before beginning"
gcloud auth activate-service-account --key-file "$GOOGLE_APPLICATION_CREDENTIALS"

if [ $? -ne 0 ] ; then
    echo "Credentials failed; no way to copy to google."
    echo "Ensure GOOGLE_APPLICATION_CREDENTIALS is appropriately set."
fi

echo "=============== NEO4J Backup ==============================="
echo "Beginning backup from $NEO4J_HOST to $BACKUP_DIR/$BACKUP_SET"
echo "To google storage bucket $GCS_BUCKET_NEO4J using credentials located at $GOOGLE_APPLICATION_CREDENTIALS"
echo "============================================================"

mkdir -p "$BACKUP_DIR/$BACKUP_SET"
NEO4J_HOST=$(kubectl get pods -n "$NEO4J_NAMESPACE" -owide | grep "$NEO4J_POD" |awk '{print $6}')
# kubectl cp "$NEO4J_NAMESPACE/$NEO4J_POD:/var/lib/neo4j/data/databases/graph.db" "$BACKUP_DIR/$BACKUP_SET/graph.db"
neo4j-admin backup --backup-dir="$BACKUP_DIR/$BACKUP_SET" --name=graph.db-backup --from="$NEO4J_HOST:$NEO4J_PORT"

echo "Backup size:"
du -hs "$BACKUP_DIR/$BACKUP_SET"

echo "Tarring -> $BACKUP_DIR/$BACKUP_SET.tar.gz"
tar -cvzf "$BACKUP_DIR/$BACKUP_SET.tar.gz" "$BACKUP_DIR/$BACKUP_SET"

echo "Zipped backup size:"
du -hs "$BACKUP_DIR/$BACKUP_SET.tar.gz"

echo "Pushing $BACKUP_DIR/$BACKUP_SET.tar.gz -> $GCS_BUCKET_NEO4J"
gsutil cp "$BACKUP_DIR/$BACKUP_SET.tar.gz" "$GCS_BUCKET_NEO4J"

echo "Neo4j backups ended"
exit $?