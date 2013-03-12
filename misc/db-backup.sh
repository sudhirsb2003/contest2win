#!/bin/sh

dbname=c2w
user=c2w
backup_dir=/mnt/db-backups
bucket=c2w-db-backups
s3_upload_cmd=/usr/bin/s3put

# You shouldn't need to edit anything beyond this line.

program=/usr/bin/pg_dump

filename=$dbname-`date +%A`.dump
filepath=$backup_dir/$filename

$program -U $user -T settings -b -Fc -f $filepath $dbname

$s3_upload_cmd $bucket/$filename $filepath
