#!/bin/sh
# SolidInvoice DE-Lokalisierung — Entrypoint Wrapper
# Wartet auf FrankenPHP-Extraktion, overlay dann DE-Übersetzungen
#
# Hintergrund: FrankenPHP extrahiert die App beim ersten Start in:
#   /root/.SolidInvoice/app_HASH/
# Der HASH ist ein Content-Hash des Binary — dynamisch, update-sicher.
# Dieses Script findet das Verzeichnis per `find` und kopiert die DE-Dateien rein.
set -e

STAGING="/opt/solidinvoice-de"
SI_HOME="/root/.SolidInvoice"

echo "[entrypoint] Starte SolidInvoice DE-Lokalisierung..."

# 1. App-Extraktion triggern (console list ist schnell, startet keinen Web-Server)
echo "[entrypoint] Triggere App-Extraktion..."
/usr/local/bin/solidinvoice console list > /dev/null 2>&1 || true

# 2. App-Verzeichnis dynamisch finden (hash-unabhängig — funktioniert nach Version-Updates!)
APP_DIR=$(find "$SI_HOME" -maxdepth 1 -name 'app_*' -type d 2>/dev/null | head -1)
if [ -z "$APP_DIR" ]; then
  echo "[entrypoint] FEHLER: App-Extraktion fehlgeschlagen — $SI_HOME/app_* nicht gefunden"
  exit 1
fi
echo "[entrypoint] App-Verzeichnis: $APP_DIR"
APP_SRC="$APP_DIR/src"

# 3. Translation-YAMLs einspielen
echo "[entrypoint] Kopiere DE-Übersetzungen..."
for BUNDLE in ClientBundle CoreBundle DashboardBundle InstallBundle InvoiceBundle \
              PaymentBundle QuoteBundle SettingsBundle TaxBundle UserBundle; do
  SRC_DIR="$STAGING/$BUNDLE"
  DST_DIR="$APP_SRC/$BUNDLE/Resources/translations"
  if [ -d "$SRC_DIR" ] && [ -d "$DST_DIR" ]; then
    for FILE in messages.de.yml email.de.yml; do
      if [ -f "$SRC_DIR/$FILE" ]; then
        cp "$SRC_DIR/$FILE" "$DST_DIR/$FILE"
        echo "[entrypoint]   ✓ $BUNDLE/$FILE"
      fi
    done
  fi
done

# 4. Twig-Templates einspielen
echo "[entrypoint] Kopiere DE-Templates..."
for ENTRY in \
  "InvoiceBundle/views/Pdf/invoice.html.twig:InvoiceBundle/Resources/views/Pdf" \
  "QuoteBundle/views/Pdf/quote.html.twig:QuoteBundle/Resources/views/Pdf" \
  "InvoiceBundle/views/Email/invoice.html.twig:InvoiceBundle/Resources/views/Email" \
  "QuoteBundle/views/Email/quote.html.twig:QuoteBundle/Resources/views/Email"; do
  SRC_REL="${ENTRY%%:*}"
  DST_DIR="$APP_SRC/${ENTRY##*:}"
  SRC="$STAGING/$SRC_REL"
  FILENAME=$(basename "$SRC_REL")
  if [ -f "$SRC" ] && [ -d "$DST_DIR" ]; then
    cp "$SRC" "$DST_DIR/$FILENAME"
    echo "[entrypoint]   ✓ $SRC_REL"
  fi
done

# 5. Symfony-Cache leeren
echo "[entrypoint] Cache leeren..."
/usr/local/bin/solidinvoice console cache:clear --env=prod --no-debug

echo "[entrypoint] DE-Lokalisierung eingespielt. Starte SolidInvoice..."

# 6. Original-Prozess starten (exec = PID 1, korrekt für Docker-Signalhandling)
exec /usr/local/bin/solidinvoice "$@"
