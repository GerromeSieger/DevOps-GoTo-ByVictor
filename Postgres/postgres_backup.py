import os
import gzip
import boto3
import subprocess
from datetime import datetime
import pytz
from botocore.exceptions import ClientError

# Define variables
BACKUP_DIR = "/var/lib/postgresql/pgbackup"
DB_NAME = "rmosvlrr"
S3_BUCKET = "pg-backup"
S3_PROFILE = "eu2"
S3_REGION = "default"
S3_ENDPOINT = "https://eu2.contabostorage.com"
LOG_FILE = "/var/lib/postgresql/postgres_backup.log"

# Define the timezone
NIGERIA_TZ = pytz.timezone('Africa/Lagos')

def log(message):
    """Logs a message with timestamp to the log file"""
    timestamp = datetime.now(NIGERIA_TZ).strftime("%Y-%m-%d_%H-%M-%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"{timestamp}: {message}\n")

def create_backup():
    """Creates a database backup and compresses it"""
    date_str = datetime.now(NIGERIA_TZ).strftime("%Y-%m-%d_%H-%M-%S")
    backup_file = f"{BACKUP_DIR}/{DB_NAME}_{date_str}.sql.gz"
    
    # Ensure backup directory exists
    os.makedirs(BACKUP_DIR, exist_ok=True)
    
    log("Backup started")
    try:
        with gzip.open(backup_file, "wt") as compressed_file:
            # Use subprocess to execute pg_dump
            subprocess.run(
                ["pg_dump", "-U", "postgres", DB_NAME],
                stdout=compressed_file,
                check=True,
            )
        log("Database backup created successfully")
        return backup_file
    except subprocess.CalledProcessError:
        log("Failed to create database backup")
        return None

def upload_to_s3(backup_file):
    """Uploads the backup file to S3"""
    session = boto3.Session(profile_name=S3_PROFILE)
    s3 = session.client("s3", endpoint_url=S3_ENDPOINT, region_name=S3_REGION)
    
    log("Uploading backup to S3")
    try:
        s3.upload_file(backup_file, S3_BUCKET, os.path.basename(backup_file))
        log("Backup successfully uploaded to S3")
    except ClientError as e:
        log(f"Failed to upload backup to S3: {e}")

def remove_oldest_local_backup():
    """Removes the oldest local backup if more than 5 exist"""
    backups = [
        f for f in os.listdir(BACKUP_DIR) if f.startswith(f"{DB_NAME}_") and f.endswith(".sql.gz")
    ]
    if len(backups) > 5:
        oldest_backup = os.path.join(BACKUP_DIR, sorted(backups)[0])
        try:
            os.remove(oldest_backup)
            log(f"Removed oldest local backup: {oldest_backup}")
        except OSError:
            log(f"Failed to remove oldest local backup: {oldest_backup}")

def remove_oldest_s3_backup():
    """Removes the oldest S3 backup if more than 5 exist"""
    session = boto3.Session(profile_name=S3_PROFILE)
    s3 = session.client("s3", endpoint_url=S3_ENDPOINT, region_name=S3_REGION)
    
    # Use list_objects_v2 to efficiently get number of objects
    paginator = s3.get_paginator("list_objects_v2")
    object_count = 0
    for page in paginator.paginate(Bucket=S3_BUCKET):
        object_count += len(page.get("Contents", []))
    
    if object_count > 5:
        response = s3.list_objects_v2(Bucket=S3_BUCKET)
        oldest_s3_backup = sorted(response['Contents'], key=lambda x: x['LastModified'])[0]['Key']
        try:
            s3.delete_object(Bucket=S3_BUCKET, Key=oldest_s3_backup)
            log(f"Removed oldest S3 backup: {oldest_s3_backup}")
        except ClientError:
            log(f"Failed to remove oldest S3 backup: {oldest_s3_backup}")

if __name__ == "__main__":
    backup_file = create_backup()
    if backup_file:
        upload_to_s3(backup_file)
        remove_oldest_local_backup()
        remove_oldest_s3_backup()
    log("Backup process completed")
