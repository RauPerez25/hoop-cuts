@echo off
rem Lo ejecuta el instalador. Descarga Python, las librerias y ffmpeg dentro de la carpeta de la app.
setlocal
cd /d "%~dp0"
set "UV_PYTHON_INSTALL_DIR=%~dp0python"
set "UV_CACHE_DIR=%~dp0cache"
set UV_PYTHON_PREFERENCE=only-managed
set UV_NO_PROGRESS=1
set UV_LINK_MODE=copy
set PIP_PAQUETES=numpy opencv-python~=4.10 rapidocr-onnxruntime pywebview

if exist venv\Scripts\python.exe (
  venv\Scripts\python.exe -c "import cv2, numpy, rapidocr_onnxruntime, webview, tkinter" >nul 2>&1 && (
    echo Python y librerias ya estaban instaladas.
    goto ffmpeg
  )
)
echo [1/4] Descargando Python 3.11 ...
uv.exe python install 3.11 || exit /b 1
echo [2/4] Preparando el entorno de la app ...
uv.exe venv --python 3.11 --allow-existing venv || exit /b 2
echo [3/4] Instalando librerias (opencv, lector de rotulos, ventana). Puede tardar unos minutos ...
uv.exe pip install --python venv\Scripts\python.exe %PIP_PAQUETES% || exit /b 3

:ffmpeg
if exist ffmpeg\ffmpeg.exe if exist ffmpeg\ffprobe.exe (
  echo ffmpeg ya estaba instalado.
  goto fin
)
echo [4/4] Descargando ffmpeg (unos 200 MB) ...
if exist fftmp rmdir /s /q fftmp
curl.exe -L --fail --retry 3 -o ffmpeg.zip "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" || exit /b 4
mkdir fftmp
tar.exe -xf ffmpeg.zip -C fftmp || exit /b 5
if not exist ffmpeg mkdir ffmpeg
for /r fftmp %%F in (ffmpeg.exe ffprobe.exe) do if exist "%%F" copy /y "%%F" ffmpeg\ >nul
rmdir /s /q fftmp
del /q ffmpeg.zip
if not exist ffmpeg\ffprobe.exe exit /b 6

:fin
if exist cache rmdir /s /q cache
venv\Scripts\python.exe -c "import cv2, numpy, rapidocr_onnxruntime, webview, tkinter; print('Comprobado: todo listo.')" || exit /b 7
exit /b 0
