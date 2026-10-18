#!/usr/bin/env bash
# instalar_sitios.sh — Instala Nginx y publica los sitios del colegio.  Uso (como root, en el servidor): bash scripts/instalar_sitios.sh
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root: bash $0"; exit 1; }

for f in "$REPO"/nginx/horizonte-www.conf "$REPO"/nginx/horizonte-portal.conf "$REPO"/nginx/00-rechazar-desconocidos.conf; do
  [[ -f $f ]] || { echo "Falta $f"; exit 1; }
done

dpkg -s nginx &>/dev/null || { apt-get update -qq; apt-get install -y -qq nginx; }

# 1. Contenido (conserva dueño root:webadmin y el setgid del Laboratorio 2)
install -d -o root -g webadmin -m 2775 /srv/horizonte/www
cp -r "$REPO"/sitio/www/. /srv/horizonte/www/
chgrp -R webadmin /srv/horizonte
find /srv/horizonte -type d -exec chmod 2775 {} +      # carpetas: equipo escribe, Nginx entra
find /srv/horizonte -type f -exec chmod 664 {} +       # archivos: equipo edita, Nginx lee (sin x)

# 2. Configuración: sites-available + enlace en sites-enabled
cp "$REPO"/nginx/horizonte-log.conf /etc/nginx/conf.d/
cp "$REPO"/nginx/00-rechazar-desconocidos.conf "$REPO"/nginx/horizonte-www.conf "$REPO"/nginx/horizonte-portal.conf /etc/nginx/sites-available/
rm -f /etc/nginx/sites-enabled/default
for sitio in 00-rechazar-desconocidos horizonte-www horizonte-portal; do
  ln -sf "/etc/nginx/sites-available/$sitio.conf" "/etc/nginx/sites-enabled/$sitio.conf"
done

# 3. Probar ANTES de recargar: si la sintaxis falla, el sitio actual sigue funcionando
nginx -t
systemctl enable nginx >/dev/null 2>&1
systemctl reload nginx 2>/dev/null || systemctl restart nginx
echo "Listo: http://www.horizonte.internal y http://portal.horizonte.internal"
