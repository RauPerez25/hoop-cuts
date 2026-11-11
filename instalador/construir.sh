#!/bin/bash
# Hace «Instalar Hoop Cuts.exe» (Windows). Necesita makensis (apt-get install nsis).
# En GitHub se construye en Windows (trae NSIS); en Linux hace falta apt-get install nsis.
# El instalador no lleva el programa: instala Python, librerías y ffmpeg, y el primer arranque
# (arranque.py) pide la clave de licencia y descarga Hoop Cuts.
set -e
F="$(cd "$(dirname "$0")" && pwd)"; OUT="${1:-$F/salida}"; VER="$(cat "$F/version_instalador.txt")"
T="$(mktemp -d)"; mkdir -p "$T/app"
cp "$F/arranque.py" "$T/app/ventana.py"; cp "$F/arranque.py" "$T/ventana.py"; echo 0 > "$T/app/version.txt"
cp "$F"/{preparar.bat,icono.ico,instalador.nsi} "$T/"
sed -i 's/\r$//; s/$/\r/' "$T/preparar.bat"
curl -sSL -o "$T/uv.zip" https://github.com/astral-sh/uv/releases/download/0.9.5/uv-x86_64-pc-windows-msvc.zip
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extract('uv.exe', sys.argv[2])" "$T/uv.zip" "$T" 2>/dev/null \
  || python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extract('uv.exe', sys.argv[2])" "$T/uv.zip" "$T"
NSIS="$(command -v makensis || echo "/c/Program Files (x86)/NSIS/makensis.exe")"
(cd "$T" && "$NSIS" -V2 -DVERSION=$VER instalador.nsi)
mkdir -p "$OUT"; cp "$T/Instalar Hoop Cuts.exe" "$OUT/"; rm -rf "$T"
echo "Hecho: $OUT/Instalar Hoop Cuts.exe ($VER)"
