#!/bin/bash

# N8N Comprehensive Backup Script
# This script creates backups of PostgreSQL database, N8N data, and configurations

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
N8N_DIR="${N8N_DIR:-/opt/n8n}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${BACKUP_DIR}/backup.log"

# Database configuration
DB_CONTAINER="n8n_postgres"
DB_NAME="${POSTGRES_DB:-n8n}"
DB_USER="${POSTGRES_USER:-n8n_user}"

# S3 configuration (optional)
S3_BUCKET="${S3_BUCKET:-}"
S3_REGION="${S3_REGION:-us-east-1}"

# Notification configuration
SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER="${SMTP_USER:-}"
SMTP_PASSWORD="${SMTP_PASSWORD:-}"
ALERT_EMAIL="${ALERT_EMAIL:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    send_alert "Backup Failed" "$1"
    exit 1
}

# Create backup directories
create_backup_dirs() {
    log "Creating backup directories..."
    mkdir -p "${BACKUP_DIR}/postgres"
    mkdir -p "${BACKUP_DIR}/n8n"
    mkdir -p "${BACKUP_DIR}/configs"
    mkdir -p "${BACKUP_DIR}/logs"
}

# Check if Docker containers are running
check_containers() {
    log "Checking Docker containers..."
    
    if ! docker ps | grep -q "$DB_CONTAINER"; then
        error "PostgreSQL container is not running"
    fi
    
    if ! docker ps | grep -q "n8n_app"; then
        error "N8N container is not running"
    fi
    
    log "All containers are running"
}

# Backup PostgreSQL database
backup_database() {
    log "Starting PostgreSQL database backup..."
    
    local backup_file="${BACKUP_DIR}/postgres/postgres_${TIMESTAMP}.sql"
    local backup_file_gz="${backup_file}.gz"
    
    # Create database dump
    docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" > "$backup_file" || {
        error "Failed to create database dump"
    }
    
    # Compress the backup
    gzip "$backup_file" || {
        error "Failed to compress database backup"
    }
    
    # Verify backup integrity
    if ! gunzip -t "$backup_file_gz"; then
        error "Database backup file is corrupted"
    fi
    
    log "Database backup completed: $backup_file_gz"
    echo "$backup_file_gz"
}

# Backup N8N data
backup_n8n_data() {
    log "Starting N8N data backup..."
    
    local backup_file="${BACKUP_DIR}/n8n/n8n_data_${TIMESTAMP}.tar.gz"
    
    # Get N8N data volume path
    local n8n_volume=$(docker volume inspect n8n_n8n_data --format '{{ .Mountpoint }}' 2>/dev/null || echo "")
    
    if [[ -z "$n8n_volume" ]]; then
        warn "N8N data volume not found, trying alternative method..."
        # Alternative: backup from container
        docker run --rm -v n8n_n8n_data:/data -v "${BACKUP_DIR}/n8n":/backup alpine tar czf "/backup/n8n_data_${TIMESTAMP}.tar.gz" -C /data . || {
            error "Failed to backup N8N data"
        }
    else
        # Direct volume backup
        tar czf "$backup_file" -C "$n8n_volume" . || {
            error "Failed to backup N8N data from volume"
        }
    fi
    
    # Verify backup
    if ! tar -tzf "$backup_file" >/dev/null; then
        error "N8N data backup file is corrupted"
    fi
    
    log "N8N data backup completed: $backup_file"
    echo "$backup_file"
}

# Backup configurations
backup_configs() {
    log "Starting configuration backup..."
    
    local backup_file="${BACKUP_DIR}/configs/configs_${TIMESTAMP}.tar.gz"
    
    # Backup N8N directory (excluding data volumes)
    tar czf "$backup_file" \
        --exclude="*.log" \
        --exclude="logs/*" \
        --exclude="data/*" \
        -C "$(dirname "$N8N_DIR")" \
        "$(basename "$N8N_DIR")" || {
        error "Failed to backup configurations"
    }
    
    # Verify backup
    if ! tar -tzf "$backup_file" >/dev/null; then
        error "Configuration backup file is corrupted"
    fi
    
    log "Configuration backup completed: $backup_file"
    echo "$backup_file"
}

# Upload to S3 (optional)
upload_to_s3() {
    local file_path="$1"
    local s3_key="$2"
    
    if [[ -z "$S3_BUCKET" ]]; then
        return 0
    fi
    
    log "Uploading to S3: $s3_key"
    
    if command -v aws >/dev/null 2>&1; then
        aws s3 cp "$file_path" "s3://$S3_BUCKET/$s3_key" --region "$S3_REGION" || {
            warn "Failed to upload $file_path to S3"
            return 1
        }
        log "Successfully uploaded to S3: $s3_key"
    else
        warn "AWS CLI not installed, skipping S3 upload"
    fi
}

# Clean old backups
cleanup_old_backups() {
    log "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    # Local cleanup
    find "${BACKUP_DIR}/postgres" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "${BACKUP_DIR}/n8n" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "${BACKUP_DIR}/configs" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    # S3 cleanup (if configured)
    if [[ -n "$S3_BUCKET" ]] && command -v aws >/dev/null 2>&1; then
        local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
        aws s3 ls "s3://$S3_BUCKET/backups/" --recursive | \
        awk '$1 < "'$cutoff_date'" {print $4}' | \
        while read -r key; do
            aws s3 rm "s3://$S3_BUCKET/$key" || warn "Failed to delete old S3 backup: $key"
        done
    fi
    
    log "Cleanup completed"
}

# Send email alert
send_alert() {
    local subject="$1"
    local message="$2"
    
    if [[ -z "$ALERT_EMAIL" || -z "$SMTP_HOST" ]]; then
        return 0
    fi
    
    local email_body="Subject: [N8N Backup] $subject
From: N8N Backup System <noreply@$(hostname)>
To: $ALERT_EMAIL

Backup Status: $subject
Timestamp: $(date)
Server: $(hostname)
Message: $message

---
N8N Backup System
"
    
    if command -v sendmail >/dev/null 2>&1; then
        echo "$email_body" | sendmail "$ALERT_EMAIL"
    elif command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "[N8N Backup] $subject" "$ALERT_EMAIL"
    else
        warn "No mail command available for sending alerts"
    fi
}

# Generate backup report
generate_report() {
    local db_backup="$1"
    local n8n_backup="$2"
    local config_backup="$3"
    
    local report_file="${BACKUP_DIR}/logs/backup_report_${TIMESTAMP}.txt"
    
    cat > "$report_file" << EOF
N8N Backup Report
================
Date: $(date)
Server: $(hostname)
Backup Directory: $BACKUP_DIR

Files Created:
- Database: $(basename "$db_backup") ($(du -h "$db_backup" | cut -f1))
- N8N Data: $(basename "$n8n_backup") ($(du -h "$n8n_backup" | cut -f1))
- Configurations: $(basename "$config_backup") ($(du -h "$config_backup" | cut -f1))

Total Backup Size: $(du -sh "$BACKUP_DIR" | cut -f1)
Retention Policy: $RETENTION_DAYS days

Status: SUCCESS
EOF
    
    log "Backup report generated: $report_file"
    
    # Send success notification
    send_alert "Backup Completed Successfully" "All backups completed successfully. See attached report for details."
}

# Main backup function
main() {
    log "Starting N8N backup process..."
    
    # Initialize
    create_backup_dirs
    check_containers
    
    # Perform backups
    local db_backup=$(backup_database)
    local n8n_backup=$(backup_n8n_data)
    local config_backup=$(backup_configs)
    
    # Upload to S3 if configured
    if [[ -n "$S3_BUCKET" ]]; then
        upload_to_s3 "$db_backup" "backups/postgres/$(basename "$db_backup")"
        upload_to_s3 "$n8n_backup" "backups/n8n/$(basename "$n8n_backup")"
        upload_to_s3 "$config_backup" "backups/configs/$(basename "$config_backup")"
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Generate report
    generate_report "$db_backup" "$n8n_backup" "$config_backup"
    
    log "Backup process completed successfully!"
}

# Run main function
main "$@"
