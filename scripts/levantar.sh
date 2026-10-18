#!/usr/bin/env bash
# levantar.sh — Aplica en el servidor la configuración de los laboratorios 2, 3 y 4.
# Uso (desde la raíz del repositorio, con los contenedores ya encendidos):  bash scripts/levantar.sh
# Usuario administrador opcional:  ADMIN_USUARIO=otro bash scripts/levantar.sh   (por defecto jhonc)
set -euo pipefail
cd "$(dirname "$0")/.."
ADMIN="${ADMIN_USUARIO:-jhonc}"
S() { docker compose exec -T "$@"; }
paso() { printf '\n==> %s\n' "$*"; }
# aplicar TITULO CMD...: ejecuta en el servidor; si falla muestra el final del registro
aplicar() {
  local salida; paso "$1"; shift
  if salida="$(S servidor "$@" 2>&1)"; then echo "$salida" | tail -n 1; else echo "$salida" | tail -n 20; echo "Falló: $*"; exit 1; fi
}

docker compose version >/dev/null || { echo "Falta Docker Compose"; exit 1; }
S servidor true 2>/dev/null || { echo "El servidor no está encendido. Ejecuta primero: docker compose up -d --build"; exit 1; }

paso "Esperando a que systemd arranque en el servidor"
e=""
for _ in $(seq 1 60); do
  e="$(S servidor systemctl is-system-running 2>/dev/null || true)"
  [[ "$e" == running || "$e" == degraded ]] && break
  sleep 2
done
echo "estado de systemd: $e"

aplicar "Laboratorio 2: usuarios, paquetes, carpetas y SSH" bash /repo/scripts/preparar_servidor.sh "$ADMIN"
S servidor bash /repo/scripts/preparar_entorno.sh "$ADMIN"
aplicar "Laboratorio 3: Nginx con los hosts virtuales www y portal" bash /repo/scripts/instalar_sitios.sh
aplicar "Laboratorio 4: PHP-FPM, portal con sesiones y proxy inverso al backend de eco" bash /repo/scripts/instalar_portal.sh

printf '\nServidor listo. Siguiente paso:  bash scripts/verificar_todo.sh\n'
printf 'Prueba rápida:  curl -H "Host: www.horizonte.internal" http://localhost:%s/\n' "${PUERTO_HTTP:-8080}"
