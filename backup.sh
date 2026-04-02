#!/bin/bash
set -euo pipefail

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# 1. Full AWS S3 Database Backup
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

echo "Full S3 Backup uploaded: $FILE"

# 2. Export Workflows to Git
GIT_DIR="/opt/n8n-git-backup" # Папка, де клоновано ваш Git-репозиторій
# (потрібно зробити git clone один раз у цю папку на сервері)

# Переходимо в директорію Git, якщо вона існує
if cd "$GIT_DIR"; then
  # Експортуємо робочі процеси; переконайтесь, що назва контейнера 'n8n' збігається
  docker exec n8n n8n export:workflow --backup --output=/data/workflows/

  # Коммітимо та пушимо
  git add workflows/
  # Додаємо '|| true' щоб скрипт не падав, якщо змін немає
  git commit -m "Automated n8n workflows backup: $DATE" || true
  git push origin main

  echo "Workflows pushed to Git"
else
  echo "Warning: GIT_DIR '$GIT_DIR' не знайдено. Пропускаю збережння в Git."
fi
