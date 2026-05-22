#!/bin/bash
# SolidInvoice DE-Lokalisierung — Deploy (Testversion, ephemer)
# Voraussetzung: Script aus dem _translations/-Verzeichnis heraus ausführen
# Auf dem Server: ssh -p 2222 martin@72.61.158.150
# Dann: bash _translations/deploy.sh
#
# ⚠️  ACHTUNG: docker cp ist EPHEMER — überlebt Container-Restart aber NICHT Coolify-Redeploy!
#              Nur für initialen Test. Danach → Dockerfile + docker-entrypoint.sh verwenden.
set -e

CONTAINER="solidinvoice"
APP_HASH="app_c2d491184dc107246fa8021abb0f6d54"
APP_BASE="/root/.SolidInvoice/${APP_HASH}/src"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== SolidInvoice DE-Lokalisierung Deploy ==="
echo "Container: $CONTAINER"
echo "App-Pfad:  /root/.SolidInvoice/${APP_HASH}/"
echo ""

# Preflight: Container vorhanden?
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "FEHLER: Container '${CONTAINER}' nicht gefunden."
  echo "Laufende Container:"
  docker ps --format '{{.Names}}'
  exit 1
fi

echo "=== Step 0: Datenbank-Backup ==="
mkdir -p /var/backups/soizburg
BACKUP_FILE="/var/backups/soizburg/solidinvoice-pre-de-$(date +%Y%m%d-%H%M%S).sql"
docker exec shared-postgres pg_dump -U solidinvoice_user solidinvoice_db > "$BACKUP_FILE"
echo "  ✓ Backup: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

echo ""
echo "=== Step 1: Translation-YAMLs kopieren ==="
for BUNDLE in ClientBundle CoreBundle DashboardBundle InstallBundle InvoiceBundle \
              PaymentBundle QuoteBundle SettingsBundle TaxBundle UserBundle; do
  SRC_DIR="$SCRIPT_DIR/translations/$BUNDLE"
  TARGET_DIR="${APP_BASE}/${BUNDLE}/Resources/translations"
  if [ -d "$SRC_DIR" ]; then
    for FILE in messages.de.yml email.de.yml; do
      if [ -f "$SRC_DIR/$FILE" ]; then
        docker cp "$SRC_DIR/$FILE" "${CONTAINER}:${TARGET_DIR}/${FILE}"
        echo "  ✓ ${BUNDLE}/${FILE}"
      fi
    done
  fi
done

echo ""
echo "=== Step 2: Twig-Templates kopieren ==="
declare -A TWIG_MAP=(
  ["InvoiceBundle/views/Pdf/invoice.html.twig"]="InvoiceBundle/Resources/views/Pdf/invoice.html.twig"
  ["QuoteBundle/views/Pdf/quote.html.twig"]="QuoteBundle/Resources/views/Pdf/quote.html.twig"
  ["InvoiceBundle/views/Email/invoice.html.twig"]="InvoiceBundle/Resources/views/Email/invoice.html.twig"
  ["QuoteBundle/views/Email/quote.html.twig"]="QuoteBundle/Resources/views/Email/quote.html.twig"
)
for SRC_REL in "${!TWIG_MAP[@]}"; do
  DST_REL="${TWIG_MAP[$SRC_REL]}"
  SRC="$SCRIPT_DIR/translations/$SRC_REL"
  if [ -f "$SRC" ]; then
    docker cp "$SRC" "${CONTAINER}:${APP_BASE}/${DST_REL}"
    echo "  ✓ ${DST_REL}"
  fi
done

echo ""
echo "=== Step 3: Symfony-Cache leeren ==="
docker exec "$CONTAINER" /usr/local/bin/solidinvoice console cache:clear --env=prod --no-debug

echo ""
echo "✅ Deploy abgeschlossen!"
echo ""
echo "=== Step 4: Locale in Coolify setzen ==="
echo "  → https://coolify.soizburg.cloud → kunden.soizburg.ai"
echo "  → Tab 'Environment Variables' → Runtime"
echo "  → SOLIDINVOICE_LOCALE = de"
echo "  → Speichern (kein Redeploy nötig)"
echo ""
echo "=== Step 5: Smoke-Test ==="
echo "  docker ps --filter 'name=solidinvoice' --format '{{.Status}}'"
echo "  docker exec solidinvoice ls /root/.SolidInvoice/${APP_HASH}/src/InvoiceBundle/Resources/translations/"
echo "  docker exec solidinvoice printenv SOLIDINVOICE_LOCALE"
echo "  curl -s -o /dev/null -w '%{http_code}' https://kunden.soizburg.ai/login"
echo ""
echo "⚠️  ACHTUNG: Änderungen NICHT persistent bei Coolify-Redeploy!"
echo "   → Für Production: Dockerfile + docker-entrypoint.sh verwenden"
