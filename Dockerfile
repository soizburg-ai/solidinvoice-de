FROM solidinvoice/solidinvoice:latest

# DE-Übersetzungen und Templates ins Image kopieren (in staging area, nicht direkt)
# Grund: FrankenPHP extrahiert die App erst beim Start in /root/.SolidInvoice/app_HASH/
# → Dateien können nicht direkt ins Zielverzeichnis gepackt werden
COPY translations/ /opt/solidinvoice-de/

# Login-Branding (SOIZBURG AI) — eigene Staging-Area
COPY login/ /opt/solidinvoice-de/login/

# PHP-Patches (hartcodierte Strings — nav labels Kunden/Zahlungen)
COPY php/ /opt/solidinvoice-de/php/

# Entrypoint-Wrapper der die Dateien nach App-Extraktion einspielt
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["run", "--disable-https"]
