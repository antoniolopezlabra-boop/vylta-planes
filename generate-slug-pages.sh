#!/bin/bash
# ══════════════════════════════════════════════════════════════════════
# Genera una pagina real por negocio: /<slug>.html
#
# Por que existe:
# GitHub Pages respondia HTTP 404 en las URLs limpias (/cris-barber) y
# dependia de un redirect por JavaScript dentro de 404.html. Eso mostraba
# pantalla en blanco a los clientes que abren el link desde el navegador
# interno de WhatsApp o con red lenta. Con una copia real por negocio la
# URL responde 200 en el primer request, sin saltos y sin JS de por medio.
#
# book.html detecta el negocio por el ultimo segmento de la ruta, asi que
# una copia tal cual funciona sin cambios.
#
# Lo ejecuta solo el workflow .github/workflows/slug-pages.yml en cada
# push a main y cada 3 horas. Tambien se puede correr a mano.
#
# 404.html se mantiene como respaldo para negocios recien dados de alta
# que todavia no tienen su pagina generada.
# ══════════════════════════════════════════════════════════════════════
set -euo pipefail

SUPABASE_URL="https://nhjmwmkaduiaifgztymi.supabase.co"
# Clave anonima publica: la misma que ya viaja en book.html. No es un secreto.
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oam13bWthZHVpYWlmZ3p0eW1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1ODk3MTYsImV4cCI6MjA4ODE2NTcxNn0.p53BZPf6qygAYw29bIJ0bA5VwZ_lRxw-aocV8LuGB1c"

# Marca al final de cada archivo generado. Permite borrar paginas de
# negocios dados de baja sin tocar jamas las paginas propias del sitio.
SENTINEL="<!-- vylta:generated-slug-page -->"

cd "$(dirname "$0")"

[ -f book.html ] || { echo "ERROR: falta book.html"; exit 1; }

echo "Consultando negocios activos..."
SLUGS=$(curl -sS --retry 3 --retry-delay 2 --max-time 30 \
  "$SUPABASE_URL/rest/v1/booking_links?is_active=eq.true&select=slug" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY" \
  | python3 -c 'import json,sys
try:
    rows = json.load(sys.stdin)
except Exception as e:
    sys.exit("respuesta invalida: %s" % e)
if not isinstance(rows, list):
    sys.exit("respuesta inesperada: %r" % rows)
for r in rows:
    s = (r.get("slug") or "").strip()
    # Solo slugs seguros: nada de rutas ni caracteres raros.
    if s and all(c.isalnum() or c in "-_" for c in s):
        print(s)')

# Si la API falla o responde vacio, no se toca nada: mejor dejar las
# paginas viejas sirviendo que borrarlas por un error temporal.
if [ -z "$SLUGS" ]; then
  echo "ERROR: sin negocios activos (API caida o respuesta vacia). No se modifica nada."
  exit 1
fi

# --- generar ---
CREATED=0
for s in $SLUGS; do
  case "$s" in book|index|404|reset) echo "  omitido (reservado): $s"; continue;; esac
  cp book.html "$s.html"
  printf '\n%s\n' "$SENTINEL" >> "$s.html"
  CREATED=$((CREATED + 1))
done

# --- limpiar negocios dados de baja ---
REMOVED=0
for f in *.html; do
  grep -qF "$SENTINEL" "$f" 2>/dev/null || continue   # no lo genero este script
  slug="${f%.html}"
  echo "$SLUGS" | grep -qxF "$slug" && continue        # sigue activo
  rm -f "$f"
  echo "  baja: $slug"
  REMOVED=$((REMOVED + 1))
done

echo "Paginas generadas: $CREATED | dadas de baja: $REMOVED"
