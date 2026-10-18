#!/usr/bin/env bash
# preparar_entorno.sh — Ajustes propios del contenedor (dentro del servidor, como root).
# Equivale a lo que hace el instalador de Ubuntu con el primer usuario: sudo sin clave (solo laboratorio)
# y grupo adm para leer /var/log/nginx.
set -euo pipefail
ADMIN="${1:-jhonc}"
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root: bash $0"; exit 1; }
echo "$ADMIN ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-horizonte
chmod 440 /etc/sudoers.d/90-horizonte
usermod -aG adm "$ADMIN"
