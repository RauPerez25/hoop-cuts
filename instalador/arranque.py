"""Primer arranque de Hoop Cuts (versión con licencia).

El instalador no lleva el programa: solo Python y este archivo, que se instala como app/ventana.py.
La primera vez pide la clave de licencia, la activa en el servidor y descarga el programa
compilado para este ordenador. Esa descarga sustituye a este archivo por el arranque de verdad,
así que a partir de ahí se abre la app normal.

Así el instalador es siempre el mismo archivo (Windows lo conoce y no avisa) y el programa
solo llega a quien tiene una licencia válida.
"""
import glob
import hashlib
import io
import json
import os
import platform
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
import zipfile

SERVIDOR = os.environ.get("HOOPCUTS_LICENCIAS", "https://hoopcuts-licencias.hoopcuts.workers.dev")
AQUI = os.path.dirname(os.path.abspath(__file__))
DATOS = os.path.dirname(AQUI) if os.path.basename(AQUI).lower() == "app" else AQUI
NARANJA, FONDO, CARTA, TEXTO, SUAVE = "#e8641b", "#151412", "#1f1d1a", "#f1ede6", "#a39c92"


def ya_instalado():
    return bool(glob.glob(os.path.join(AQUI, "ventana.*.pyd")) or glob.glob(os.path.join(AQUI, "ventana.*.so")))


# Tiene que dar EXACTAMENTE lo mismo que licencia.maquina() de la app (si no, el pase no vale).
def maquina():
    fijo = None
    try:
        if os.name == "nt":
            import winreg
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Cryptography") as k:
                fijo = winreg.QueryValueEx(k, "MachineGuid")[0]
        elif platform.system() == "Darwin":
            out = subprocess.run(["ioreg", "-rd1", "-c", "IOPlatformExpertDevice"], capture_output=True, text=True, timeout=5).stdout
            for linea in out.splitlines():
                if "IOPlatformUUID" in linea:
                    fijo = linea.split('"')[-2]
        elif os.path.exists("/etc/machine-id"):
            with open("/etc/machine-id") as f:
                fijo = f.read().strip()
    except Exception:
        fijo = None
    if not fijo:
        ruta = os.path.join(DATOS, "maquina.txt")
        try:
            with open(ruta, encoding="utf-8") as f:
                fijo = f.read().strip()
        except OSError:
            fijo = ""
        if not fijo:
            fijo = uuid.uuid4().hex
            with open(ruta, "w", encoding="utf-8") as f:
                f.write(fijo)
    return hashlib.sha256((platform.system() + "|" + fijo).encode()).hexdigest()[:32]


def plataforma():
    if os.name == "nt":
        return "windows"
    if platform.system() == "Darwin":
        return "mac-arm" if platform.machine() == "arm64" else "mac-intel"
    return "linux"


def pide(ruta, cuerpo, espera=30):
    pet = urllib.request.Request(SERVIDOR + ruta, data=json.dumps(cuerpo).encode(), method="POST",
                                 headers={"content-type": "application/json", "user-agent": "HoopCuts"})
    try:
        with urllib.request.urlopen(pet, timeout=espera) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        try:
            msg = json.loads(e.read()).get("error")
        except ValueError:
            msg = None
        raise RuntimeError(msg or f"el servidor ha contestado {e.code}") from e
    except (urllib.error.URLError, OSError) as e:
        raise RuntimeError("No hay conexión con el servidor de Hoop Cuts. Comprueba tu internet.") from e


def instala(clave, avisa):
    """Activa la clave y descarga el programa. Lanza RuntimeError con un texto claro si algo falla."""
    clave = clave.strip().upper()
    if not clave:
        raise RuntimeError("Escribe tu clave de licencia.")
    m = maquina()
    avisa("Comprobando la licencia…")
    r = json.loads(pide("/api/licencia", {"clave": clave, "maquina": m, "equipo": (platform.node() or "")[:60], "version": "0"}))
    if not r.get("ok"):
        raise RuntimeError(r.get("error") or "No se ha podido activar la licencia.")
    tmp = os.path.join(DATOS, "licencia.json.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump({"clave": clave, "pase": r["pase"], "comprobado": int(time.time())}, f)
    os.replace(tmp, os.path.join(DATOS, "licencia.json"))
    cuerpo = {"clave": clave, "maquina": m, "plataforma": plataforma()}
    v = json.loads(pide("/api/version", cuerpo))
    if not v.get("ok") or plataforma() not in (v.get("plataformas") or []):
        raise RuntimeError(v.get("error") or "Todavía no hay versión de Hoop Cuts para este ordenador.")
    avisa("Descargando Hoop Cuts…")
    z = zipfile.ZipFile(io.BytesIO(pide("/api/descarga", cuerpo, espera=300)))
    nombres = [n for n in z.namelist() if not n.endswith("/") and n != "version.txt"]
    if not any(n.startswith("app.") for n in nombres) or any(os.path.basename(n) != n or n.startswith(".") for n in nombres):
        raise RuntimeError("La descarga ha llegado incompleta. Vuelve a intentarlo.")
    avisa("Instalando…")
    for n in nombres:  # este mismo archivo (ventana.py) también se sustituye: ya está cargado, no pasa nada
        with open(os.path.join(AQUI, n + ".nuevo"), "wb") as f:
            f.write(z.read(n))
    for n in nombres:
        os.replace(os.path.join(AQUI, n + ".nuevo"), os.path.join(AQUI, n))
    with open(os.path.join(AQUI, "version.txt"), "w", encoding="utf-8") as f:
        f.write(v["version"])


def abre_app():
    exe = sys.executable
    if os.name == "nt":  # sin consola
        w = os.path.join(os.path.dirname(exe), "pythonw.exe")
        exe = w if os.path.exists(w) else exe
    subprocess.Popen([exe, os.path.join(AQUI, "ventana.py")], cwd=AQUI)


def ventana_clave():
    import tkinter as tk

    raiz = tk.Tk()
    raiz.title("Hoop Cuts")
    raiz.configure(bg=FONDO)
    raiz.resizable(False, False)
    try:
        raiz.iconbitmap(os.path.join(DATOS, "icono.ico"))
    except Exception:
        pass
    c = tk.Frame(raiz, bg=CARTA, padx=26, pady=22)
    c.pack(padx=18, pady=18)
    t = tk.Frame(c, bg=CARTA)
    t.pack(anchor="w")
    tk.Label(t, text="Bienvenido a ", font=("Segoe UI", 16, "bold"), fg=TEXTO, bg=CARTA).pack(side="left")
    tk.Label(t, text="Hoop Cuts", font=("Segoe UI", 16, "bold"), fg=NARANJA, bg=CARTA).pack(side="left")
    tk.Label(c, text="Escribe la clave de tu licencia para terminar la instalación.\nSolo hace falta la primera vez.",
             font=("Segoe UI", 10), fg=SUAVE, bg=CARTA, justify="left").pack(anchor="w", pady=(6, 14))
    var = tk.StringVar()
    e = tk.Entry(c, textvariable=var, font=("Consolas", 14), width=24, bg=FONDO, fg=TEXTO, insertbackground=TEXTO,
                 relief="flat", highlightthickness=1, highlightbackground="#4a443d", highlightcolor=NARANJA)
    e.pack(fill="x", ipady=7)
    msg = tk.Label(c, text="", font=("Segoe UI", 10), fg="#ff8a7a", bg=CARTA, wraplength=330, justify="left")
    msg.pack(anchor="w", pady=(8, 8))
    b = tk.Button(c, text="Activar e instalar", font=("Segoe UI", 11, "bold"), fg="white", bg=NARANJA,
                  activebackground="#c9520f", activeforeground="white", relief="flat", padx=16, pady=7, cursor="hand2")
    b.pack(anchor="e")
    ok = {"v": False}

    def avisa(texto, error=False):
        raiz.after(0, lambda: msg.config(text=texto, fg="#ff8a7a" if error else SUAVE))

    def trabaja():
        try:
            instala(var.get(), avisa)
            ok["v"] = True
            raiz.after(0, raiz.destroy)
        except Exception as ex:  # noqa: BLE001  (cualquier fallo se enseña tal cual)
            avisa(str(ex), True)
            raiz.after(0, lambda: (b.config(state="normal"), e.config(state="normal")))

    def pulsa(_=None):
        b.config(state="disabled")
        e.config(state="disabled")
        threading.Thread(target=trabaja, daemon=True).start()

    b.config(command=pulsa)
    e.bind("<Return>", pulsa)
    e.focus_set()
    raiz.update_idletasks()
    x = (raiz.winfo_screenwidth() - raiz.winfo_width()) // 2
    y = (raiz.winfo_screenheight() - raiz.winfo_height()) // 3
    raiz.geometry(f"+{x}+{y}")
    raiz.mainloop()
    return ok["v"]


def main():
    if ya_instalado():
        # el programa ya está (p. ej. al reinstalar encima): este archivo ha pisado el arranque, lo abrimos igual
        sys.path.insert(0, AQUI)
        import ventana  # carga el compilado, que va antes que este .py
        ventana.main()
        return
    if ventana_clave():
        abre_app()


if __name__ == "__main__":
    main()
