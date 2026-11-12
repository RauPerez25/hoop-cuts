#!/bin/bash
# Hace el instalador de Mac de la versión con licencia: «Hoop-Cuts-Mac.zip» con «Hoop Cuts.app».
# Uso: bash instalador/construir_mac.sh [carpeta_salida]   (por defecto dist/)
#
# Igual que el de Windows, NO lleva el programa: la app instala Python, las librerías y ffmpeg,
# y abre el primer arranque (instalador/fuente/arranque.py), que pide la clave y descarga el
# programa compilado para Mac (solo Mac con chip de Apple).
set -e
F="$(cd "$(dirname "$0")" && pwd)"; OUT="${1:-$(dirname "$F")/dist}"
VER="$(cat "$F/version_instalador.txt")"
T="$(mktemp -d)"
A="$T/Hoop Cuts.app/Contents"; mkdir -p "$A/MacOS" "$A/Resources"
cp "$F/mac/HoopCutsLicencia" "$A/MacOS/HoopCuts"; chmod 755 "$A/MacOS/HoopCuts"
cp "$F/arranque.py" "$A/Resources/arranque.py"; chmod 644 "$A/Resources/arranque.py"
cp "$F/icono.icns" "$A/Resources/"; echo "$VER" > "$A/Resources/version.txt"
sed "s/__VERSION__/$VER/g; s/es.privado.cortespartido/es.hoopcuts.app/; s/<string>CortesPartido</<string>HoopCuts</" "$F/mac/Info.plist" > "$A/Info.plist"
cat > "$T/LEEME - como abrirla.txt" <<'TXT'
HOOP CUTS - Mac (necesita un Mac con chip de Apple: M1, M2, M3...)

1. Arrastra "Hoop Cuts" a la carpeta Aplicaciones y ábrela.
2. La primera vez, el Mac dirá que no puede comprobar la app (no está firmada por Apple).
   - Ve a Ajustes del Sistema > Privacidad y seguridad.
   - Abajo verás "Se ha bloqueado Hoop Cuts": pulsa "Abrir igualmente" y confirma.
3. La primera vez descarga lo que necesita (unos 500 MB, 5-15 minutos, hace falta internet).
   Al terminar te pide tu clave de licencia: escríbela y pulsa "Activar e instalar".
   Las siguientes veces se abre directamente.

Si algo falla, el detalle está en:
~/Library/Application Support/HoopCuts/instalacion.log
TXT
mkdir -p "$OUT"; rm -f "$OUT/Hoop-Cuts-Mac.zip"
(cd "$T" && zip -r -X -q "$OUT/Hoop-Cuts-Mac.zip" "Hoop Cuts.app" "LEEME - como abrirla.txt")
rm -rf "$T"; echo "Hecho: $OUT/Hoop-Cuts-Mac.zip (instalador $VER)"
