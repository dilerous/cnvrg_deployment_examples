#!/bin/bash

TODAY_DATE=$(date "+%Y-%m-%d")
PG_DUMP=/backup-data/cnvrg-db-backup.sql
REDIS_DUMP=/backup-data/dump.rdb
NUM_BACKUP_KEEP=5

echo "Checking object storage..."
if [ "$CNVRG_STORAGE_TYPE" == "minio" ] || [ "$CNVRG_STORAGE_TYPE" == "aws" ]; then
    printf "Object storage type is ${CNVRG_STORAGE_TYPE}, continuing with backup.\n"
else
    printf "Object storage type is ${CNVRG_STORAGE_TYPE}, which isn't supported.\nExitting backup plan.\n"
    exit 1
fi

echo "Connecting to object storage..."
mc alias set $CNVRG_STORAGE_TYPE $CNVRG_STORAGE_ENDPOINT $CNVRG_STORAGE_ACCESS_KEY $CNVRG_STORAGE_SECRET_KEY --api S3v4
test_bucket=$(mc ls $CNVRG_STORAGE_TYPE/$CNVRG_STORAGE_BUCKET | wc -l)
if [ $test_bucket -gt 0 ]
then
  echo "Connected successfully"
else
  echo "Connection failed, exitting"
  exit 1
fi

echo "Performing Postgres database backup..."
echo $PG_PASSWORD | pg_dump -h postgres -U cnvrg -d cnvrg_production -Fc -v > $PG_DUMP

if [ -f $PG_DUMP ]; then
    echo "File '$PG_DUMP' saved, Postgres backup was successful"
else
    echo "File '$PG_DUMP' does not exist. Backup failed, exitting"
    exit 1
fi

echo "Checking Redis connection..."
REDIS_PASS=$(cat /etc/secret/redis.conf | awk 'END{print $2}')

echo "Creating Redis dump file locally..."
redis-cli -h redis -a $REDIS_PASS --rdb $REDIS_DUMP

if [ -f $REDIS_DUMP ]; then
    echo "'$REDIS_DUMP' saved, Redis backup was successful"
else
    echo "'$REDIS_DUMP' does not exist, The backup failed. continuing for PG backup only."
fi

echo "Compressing the backups for upload..."
REDIS_TAR=redis-backup-${TODAY_DATE}.tar.gz
PG_TAR=pg-backup-${TODAY_DATE}.tar.gz

tar -zcvf $REDIS_TAR $REDIS_DUMP
tar -zcvf $PG_TAR $PG_DUMP

echo "Copying the Redis and Postgres Database to object storage"
mc cp $REDIS_TAR $CNVRG_STORAGE_TYPE/$CNVRG_STORAGE_BUCKET/$REDIS_TAR
mc cp $PG_TAR $CNVRG_STORAGE_TYPE/$CNVRG_STORAGE_BUCKET/$PG_TAR

echo "Number of backups to keep is set to:" ${NUM_BACKUP_KEEP}
echo "Checking if older backups need to be deleted..."

CURRENT_PG_NUM=$(mc ls minio/cnvrg-storage | grep pg-backup | wc -l)
CURRENT_REDIS_NUM=$(mc ls minio/cnvrg-storage | grep redis-backup | wc -l)

echo "Current number of Postgres backups is:" ${CURRENT_PG_NUM}
echo "Current number of Redis backups is:" ${CURRENT_REDIS_NUM}

while [ "$CURRENT_PG_NUM" -gt "$NUM_BACKUP_KEEP" ]
do
    PG_OLDEST_BACKUP=$(mc ls minio/cnvrg-storage | grep pg-backup | sort | head -n 1 | awk '{print $6}')
    echo "Deleting the oldest backup" $PG_OLDEST_BACKUP
    mc rm minio/cnvrg-storage/$PG_OLDEST_BACKUP
    CURRENT_PG_NUM=$(mc ls minio/cnvrg-storage | grep pg-backup | wc -l)
done
echo "Finished cleaning up old Postgres backups"

while [ "$CURRENT_REDIS_NUM" -gt "$NUM_BACKUP_KEEP" ]
do
    REDIS_OLDEST_BACKUP=$(mc ls minio/cnvrg-storage | grep redis-backup | sort | head -n 1 | awk '{print $6}')
    echo "Deleting the oldest backup" $REDIS_OLDEST_BACKUP
    mc rm minio/cnvrg-storage/$REDIS_OLDEST_BACKUP
    CURRENT_REDIS_NUM=$(mc ls minio/cnvrg-storage | grep redis-backup | wc -l)
done
echo "Finished cleaning up old Redis backups"

echo "Here is a list of your backups"
echo "Postgres"
mc ls minio/cnvrg-storage | grep pg-backup | awk '{print $6}'
echo ""
echo "Redis"
mc ls minio/cnvrg-storage | grep redis-backup | awk '{print $6}'



echo ""
echo "Backup finished:"
mc ls $CNVRG_STORAGE_TYPE/$CNVRG_STORAGE_BUCKET/$REDIS_TAR
mc ls $CNVRG_STORAGE_TYPE/$CNVRG_STORAGE_BUCKET/$PG_TAR
