# VYLTA — Troubleshooting: book.vylta.lat caído

Checklist en orden. Revisar SIEMPRE de arriba hacia abajo — no saltar pasos.

---

## PASO 1 — Verificar Namecheap (LA RAÍZ)
👉 https://ap.www.namecheap.com/domains/list/

Verificar:
- [ ] `vylta.lat` muestra **ACTIVE** (no Suspended, no Expired)
- [ ] Auto-Renew está **ON**
- [ ] No hay alertas ni banners de verificación pendiente

**Si está suspendido:** Buscar email de Namecheap en hotmail con asunto
"Action required: Verify your contact information" y hacer clic en el link de verificación.

**Comando rápido para verificar nameservers:**
```bash
dig NS vylta.lat +short
```
Debe responder: `guy.ns.cloudflare.com` y `simone.ns.cloudflare.com`
Si responde `verify-contact-details.namecheap.com` → dominio suspendido, ir a Namecheap.

---

## PASO 2 — Verificar Cloudflare DNS
👉 https://dash.cloudflare.com/38d335e24c9e178cfca7d2ff52402807/vylta.lat/dns/records

Verificar que existan estos registros:

| Type  | Name | Content | Proxy |
|-------|------|---------|-------|
| CNAME | book | antoniolopezlabra-boop.github.io | DNS only (nube gris) |

**Si no existe el CNAME:** Crearlo con esos valores exactos. Proxy SIEMPRE en DNS only.

**Comando rápido:**
```bash
dig @guy.ns.cloudflare.com book.vylta.lat CNAME +short
```
Debe responder: `antoniolopezlabra-boop.github.io.`

---

## PASO 3 — Verificar GitHub Pages
👉 https://github.com/antoniolopezlabra-boop/vylta-planes/settings/pages

Verificar:
- [ ] "Your site is live at https://book.vylta.lat/"
- [ ] Custom domain = `book.vylta.lat`
- [ ] No hay error rojo de DNS
- [ ] Enforce HTTPS está activado

**Si hay error NotServedByPagesError:**
1. Verificar que el dominio esté verificado en GitHub: https://github.com/settings/pages
2. Si no está verificado, ir al Paso 4.

---

## PASO 4 — Verificar dominio en GitHub (si hay NotServedByPagesError)
👉 https://github.com/settings/pages

- [ ] `vylta.lat` aparece en **Verified domains**

**Si no está verificado:**
1. Clic en "Add a domain" → escribir `vylta.lat`
2. GitHub da un código TXT — agregar en Cloudflare:
   - Type: TXT
   - Name: `_github-pages-challenge-antoniolopezlabra-boop`
   - Content: el código que da GitHub
   - TTL: 1 min
3. Esperar 5 minutos y dar clic en "Verify"

---

## PASO 5 — Verificar archivo CNAME del repo
👉 https://github.com/antoniolopezlabra-boop/vylta-planes/blob/main/CNAME

El archivo debe contener exactamente:
```
book.vylta.lat
```

**Si está vacío o tiene otro contenido:** Editarlo y poner `book.vylta.lat`.

---

## PASO 6 — Test final
```bash
# Debe responder 200 OK (no 301 ni error)
curl -I https://book.vylta.lat/book.html?n=vylta-demo

# Debe responder: antoniolopezlabra-boop.github.io.
dig book.vylta.lat CNAME +short
```

---

## Link de emergencia (funciona aunque book.vylta.lat esté caído)
```
https://antoniolopezlabra-boop.github.io/vylta-planes/book.html?n=SLUG
```
Reemplazar SLUG con el slug del negocio (ej: `marchitas`, `karen-nails-star-heart`).

---

## Emails críticos a NO ignorar
| Remitente | Asunto | Acción |
|-----------|--------|--------|
| support@namecheap.com | "Action required: Verify your contact information" | Verificar INMEDIATAMENTE — plazo de 5 días |
| noreply@notify.cloudflare.com | "stopped using Cloudflare's nameservers" | Revisar Namecheap Paso 1 |
| noreply@github.com | Cualquier alerta de Pages | Revisar Paso 3 y 4 |

---

## Historial de incidentes
| Fecha | Causa | Solución |
|-------|-------|--------|
| 2026-04-11 | Namecheap suspendió vylta.lat por WHOIS no verificado — Cloudflare perdió control del DNS | Verificar email WHOIS en Namecheap → dominio reactivado → re-verificar en GitHub |
