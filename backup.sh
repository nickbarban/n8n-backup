#!/bin/bash
set -euo pipefail

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUT_DIR="$HOME/n8n-backup"
FILE="n8n-backup-$DATE.tar.gz"
BUCKET="s3://nickbarban-n8n-backups"

docker run --rm \
  -v n8n_n8n_data:/data:ro \
  -v "$OUT_DIR:/backup" \
  alpine \
  sh -c "tar -czf /backup/$FILE -C /data ."

aws s3 cp "$OUT_DIR/$FILE" "$BUCKET/$FILE"
rm -f "$OUT_DIR/$FILE"

echo "Backup uploaded: $FILE"
