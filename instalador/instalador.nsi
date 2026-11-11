; Instalador de "Hoop Cuts" para Windows (se compila con makensis)
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"

!ifndef VERSION
  !define VERSION "1.0"
!endif
!define NOMBRE "Hoop Cuts"
!define CLAVE "Software\Microsoft\Windows\CurrentVersion\Uninstall\CortesPartido"

Name "${NOMBRE}"
OutFile "Instalar Hoop Cuts.exe"
InstallDir "$LOCALAPPDATA\CortesPartido"
RequestExecutionLevel user
SetCompressor /SOLID lzma
ShowInstDetails show
ShowUninstDetails show
BrandingText "${NOMBRE} ${VERSION}"
VIProductVersion "1.0.0.0"
VIAddVersionKey /LANG=1034 "ProductName" "${NOMBRE}"
VIAddVersionKey /LANG=1034 "FileDescription" "Instalador de ${NOMBRE}"
VIAddVersionKey /LANG=1034 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1034 "LegalCopyright" "Uso privado"

!define MUI_ICON "icono.ico"
!define MUI_UNICON "icono.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Instalar ${NOMBRE}"
!define MUI_WELCOMEPAGE_TEXT "Esto instala la app para detectar y cortar las jugadas de los partidos.$\r$\n$\r$\nHace falta internet: el instalador descarga Python, las librerías y ffmpeg (unos 600 MB en total). Tarda entre 5 y 15 minutos según la conexión.$\r$\n$\r$\nNo necesita permisos de administrador."
!define MUI_FINISHPAGE_TITLE "${NOMBRE} está instalado"
!define MUI_FINISHPAGE_TEXT "Tienes un acceso directo en el Escritorio y en el menú Inicio."
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Abrir ${NOMBRE} ahora"
!define MUI_FINISHPAGE_RUN_FUNCTION Abrir

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Spanish"

Function Abrir
  SetOutPath "$INSTDIR\app"
  Exec '"$INSTDIR\venv\Scripts\pythonw.exe" "$INSTDIR\app\ventana.py"'
FunctionEnd

Section "Instalar"
  SetOutPath "$INSTDIR\app"
  File "app\*.py"
  File /nonfatal "app\*.html"
  File /nonfatal "app\*.js"
  File /nonfatal "app\version.txt"
  File "ventana.py"
  SetOutPath "$INSTDIR"
  File "uv.exe"
  File "preparar.bat"
  File "icono.ico"
  WriteUninstaller "$INSTDIR\Desinstalar.exe"

  DetailPrint "Descargando e instalando lo necesario. No cierres esta ventana..."
  nsExec::ExecToLog '"$SYSDIR\cmd.exe" /c ""$INSTDIR\preparar.bat""'
  Pop $0
  ${If} $0 != "0"
    MessageBox MB_ICONSTOP "No se pudo terminar la instalación (paso con error: $0).$\r$\n$\r$\nComprueba que hay internet y vuelve a abrir el instalador: seguirá por donde se quedó."
    Abort
  ${EndIf}

  SetOutPath "$INSTDIR\app"
  Delete "$DESKTOP\Cortes de partido.lnk"
  Delete "$SMPROGRAMS\Cortes de partido.lnk"
  CreateShortCut "$DESKTOP\${NOMBRE}.lnk" "$INSTDIR\venv\Scripts\pythonw.exe" '"$INSTDIR\app\ventana.py"' "$INSTDIR\icono.ico" 0
  CreateShortCut "$SMPROGRAMS\${NOMBRE}.lnk" "$INSTDIR\venv\Scripts\pythonw.exe" '"$INSTDIR\app\ventana.py"' "$INSTDIR\icono.ico" 0

  WriteRegStr HKCU "${CLAVE}" "DisplayName" "${NOMBRE}"
  WriteRegStr HKCU "${CLAVE}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${CLAVE}" "DisplayIcon" "$INSTDIR\icono.ico"
  WriteRegStr HKCU "${CLAVE}" "Publisher" "Hoop Cuts"
  WriteRegStr HKCU "${CLAVE}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${CLAVE}" "UninstallString" '"$INSTDIR\Desinstalar.exe"'
  WriteRegDWORD HKCU "${CLAVE}" "NoModify" 1
  WriteRegDWORD HKCU "${CLAVE}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\${NOMBRE}.lnk"
  Delete "$SMPROGRAMS\${NOMBRE}.lnk"
  SetOutPath "$TEMP"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "${CLAVE}"
SectionEnd
