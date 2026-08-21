#!/bin/bash
# ══════════════════════════════════════════════════════════════════════
# Genera una pagina REAL por cada negocio: /<slug>/index.html
#
# Por que: GitHub Pages respondia 404 en /<slug> y dependia de un redirect
# por JavaScript (404.html). Eso mostraba pantalla en blanco a clientes que
# abren el link desde el navegador interno de WhatsApp/Instagram o con red
# lenta. Con una pagina real, la URL responde 200 al instante y sin saltos.
#
# book.html detecta el negocio por la ruta, asi que una copia funciona igual.
# Regenerar tras cambiar book.html o dar de alta un negocio nuevo.
# ══════════════════════════════════════════════════════════════════════
set -e
SB="https://nhjmwmkaduiaifgztymi.supabase.co"
ANON="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oam13bWthZHVpYWlmZ3p0eW1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1ODk3MTYsImV4cCI6MjA4ODE2NTcxNn0.p53BZPf6qygAYw29bIJ0bA5VwZ_lRxw-aocV8LuGB1c"
cd "$(dirname "$0")"

SLUGS=$(curl -s --max-time 30 "$SB/rest/v1/booking_links?is_active=eq.true&select=slug" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  | python3 -c "import json,sys;[print(r['slug']) for r in json.load(sys.stdin) if r.get('slug')]")

[ -z "$SLUGS" ] && { echo "Sin slugs (¿API caida?). No se toca nada."; exit 1; }

N=0
for s in $SLUGS; do
  case "$s" in book.html|index.html|assets|"") continue;; esac
  :
  cp book.html "$s.html"
  N=$((N+1))
done
echo "Paginas generadas: $N"
