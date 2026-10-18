#!/usr/bin/env bash
# verificar_todo.sh — Ejecuta los tres verificadores dentro del servidor y muestra un resumen.
# Uso (desde la raíz del repositorio):  bash scripts/verificar_todo.sh
# Para firmar la salida:  AUTOR="Nombre Apellido" bash scripts/verificar_todo.sh
cd "$(dirname "$0")/.."
ADMIN="${ADMIN_USUARIO:-jhonc}"
S() { docker compose exec -T -e AUTOR="${AUTOR:-}" -e ADMIN_USUARIO="$ADMIN" servidor "$@"; }
fallos=0; resumen=""
for n in 02 03 04; do
  printf '\n===== Verificador del laboratorio %s =====\n' "${n#0}"
  salida="$(S bash "/repo/scripts/verificar_lab$n.sh" 2>&1)" || fallos=$((fallos + 1))
  echo "$salida"
  resumen+="Laboratorio ${n#0}: $(grep -o 'Resultado: [0-9]* de [0-9]*' <<<"$salida" || echo 'sin resultado')"$'\n'
done
printf '\n===== Resumen =====\n%s' "$resumen"
if [[ $fallos -eq 0 ]]; then echo "TODO CORRECTO"; else echo "Hay $fallos verificador(es) con fallos"; fi
[[ -n "${AUTOR:-}" ]] && echo "$AUTOR"
[[ $fallos -eq 0 ]]
