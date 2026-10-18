#!/usr/bin/env bash
# preparar_servidor.sh — Deja el servidor de la U.E. Horizonte listo (usuarios, paquetes, carpetas, SSH).
# Uso (dentro del servidor, como root):  bash preparar_servidor.sh <usuario_admin>
# Es IDEMPOTENTE: ejecutarlo dos veces no rompe nada. Se comprueba con:  bash verificar_lab02.sh <usuario_admin>
set -euo pipefail

USUARIO="${1:-}"
if [[ $EUID -ne 0 ]]; then echo "Ejecuta como root: bash $0 <usuario>"; exit 1; fi
if [[ -z "$USUARIO" ]]; then echo "Falta el usuario: bash $0 <usuario>"; exit 1; fi

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

paso "1. Nombre del servidor y zona horaria"
hostnamectl set-hostname srv-horizonte 2>/dev/null || echo srv-horizonte > /etc/hostname
# Zona horaria: idempotente (fijar el mismo valor dos veces no cambia nada). Si no hay timedated (contenedor), se enlaza el archivo.
timedatectl set-timezone America/La_Paz 2>/dev/null || { ln -sf /usr/share/zoneinfo/America/La_Paz /etc/localtime; echo America/La_Paz > /etc/timezone; }

paso "2. Paquetes base"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl htop tree ufw unattended-upgrades   # apt ya omite lo instalado

paso "3. Usuario administrador con sudo"
if ! id "$USUARIO" &>/dev/null; then
  adduser --disabled-password --gecos "Administrador Horizonte" "$USUARIO"
fi
usermod -aG sudo "$USUARIO"   # -a = AÑADIR; sin -a, -G REEMPLAZA todos los grupos secundarios

paso "4. Grupo webadmin y carpeta del sitio"
getent group webadmin >/dev/null || groupadd webadmin
usermod -aG webadmin "$USUARIO"
# install -d crea la carpeta si no existe y, si existe, solo reajusta dueño y permisos (2775 = setgid + rwxrwxr-x)
install -d -o root -g webadmin -m 2775 /srv/horizonte/www /srv/horizonte/portal
if [[ ! -f /srv/horizonte/www/index.html ]]; then
  cat > /srv/horizonte/www/index.html <<'HTML'
<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>U.E. Horizonte</title></head>
<body><h1>U.E. Horizonte</h1><p>Servidor srv-horizonte listo.</p></body></html>
HTML
  chown root:webadmin /srv/horizonte/www/index.html; chmod 664 /srv/horizonte/www/index.html
fi

paso "5. Nombres locales (hasta que tengamos DNS propio en la laboratorio de DNS)"
for nombre in www.horizonte.internal portal.horizonte.internal; do
  grep -q " $nombre" /etc/hosts || echo "127.0.1.1 $nombre" >> /etc/hosts
done

paso "6. Servicio SSH habilitado y activo"
systemctl enable --now ssh   # enable = arranque futuro; --now = además iniciar ya

paso "7. RETO 1: usuario 'comunicacion' solo en webadmin (sin sudo)"
if ! id comunicacion &>/dev/null; then
  adduser --disabled-password --gecos "Equipo de comunicacion" comunicacion
fi
usermod -aG webadmin comunicacion   # solo webadmin; nunca sudo

paso "8. RETO 2: unattended-upgrades con reinicio automatico a las 03:00"
# Se sobrescribe el mismo archivo cada vez: idempotente. Riesgo: un reinicio sin supervision corta los servicios unos minutos.
cat > /etc/apt/apt.conf.d/52reinicio-horizonte <<'CONF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
CONF

paso "Resumen"
echo "Usuario: $USUARIO  →  grupos: $(id -nG "$USUARIO")"
ls -ld /srv/horizonte /srv/horizonte/www 2>/dev/null || echo "Aún no existe /srv/horizonte"
systemctl is-active ssh || true
