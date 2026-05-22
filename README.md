# SolidInvoice DE-Lokalisierung

Deutsche Übersetzungen und Dockerfile für [SolidInvoice](https://solidinvoice.co) v2.3.17.

Ziel: `kunden.soizburg.ai` vollständig auf Deutsch.

## Struktur

```
translations/
├── ClientBundle/messages.de.yml + email.de.yml
├── CoreBundle/messages.de.yml
├── DashboardBundle/messages.de.yml
├── InstallBundle/messages.de.yml
├── InvoiceBundle/messages.de.yml + email.de.yml + views/
├── PaymentBundle/messages.de.yml + email.de.yml
├── QuoteBundle/messages.de.yml + email.de.yml + views/
├── SettingsBundle/messages.de.yml
├── TaxBundle/messages.de.yml
└── UserBundle/messages.de.yml + email.de.yml
Dockerfile
docker-entrypoint.sh
deploy.sh (ephemer, nur für Phase-1-Test)
```

## Deployment

**Phase 1 (Test/ephemer):**
```bash
git clone https://github.com/soizburg-ai/solidinvoice-de /tmp/si-translations/
cd /tmp/si-translations
cat deploy.sh   # DIAGNOSE-PFLICHT
bash deploy.sh
```

**Phase 2 (Production):** Coolify Git-Build mit diesem Repo.

## Hinweise

- FrankenPHP: kein `php` in PATH. Immer `/usr/local/bin/solidinvoice console`
- App-Pfad: `/root/.SolidInvoice/app_HASH/src/` (nicht `/var/www/html/`)
- `SOLIDINVOICE_LOCALE=de` als Runtime-Env-Variable in Coolify setzen
