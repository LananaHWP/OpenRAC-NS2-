#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""OpenRAC for the Nintendo Switch 2: puts the game on the console from the player's own disc image, onto an SD card in this PC or over FTP.

    python3 switch2_setup.py                       a window: pick the disc image, then the SD card or the console's FTP address, and Install
    python3 switch2_setup.py --cli                 the same by questions in the terminal (no window needed)
    python3 switch2_setup.py --cli --iso GAME.iso --sd E:\\ [--arsenal-mastery]
    python3 switch2_setup.py --cli --iso GAME.iso --ftp 192.168.1.50[:1337] [--ftp-user U --ftp-password P --ftp-root /]

What it does (everything goes to the switch/openrac folder of the card, nothing to the console's own storage):
  1. checks the image is a disc OpenRAC knows (Ratchet & Clank, NTSC-U) and there is room;
  2. writes the boot files and the disc image (the game reads most of its data from the disc by sector)  -> data/iso_data/rac1/
  3. exports the levels the renderer draws, from the disc                                                  -> data/port/ntsc/
  4. copies the program (openrac.nro) and its pictures (the Switch button prompts, the help screen)    -> openrac.nro, data/texture_packs/
  5. optionally the Arsenal Mastery mod (an optional extra: leave it out for the original game)         -> data/plugins/

To an SD card the files are written straight onto it. Over FTP they are made in a work folder next to the disc image (about 1 GB; the image itself is
linked, not copied, when that folder is on the same drive) and uploaded to the console's FTP server (the homebrew FTP servers of the Switch: start
one, note the address it shows). An upload that stops is resumed from where it was (run the setup again). The work folder is deleted afterwards.

No part of the game is shipped: steps 2 and 3 read the player's own disc. Needs Python 3.9 or newer (the standard library only).
The bundle (openrac.nro, the pictures, the mod) is the folder `bundle` next to this file, or --bundle DIR.
"""
import argparse
import ftplib
import json
import pathlib
import queue
import shutil
import subprocess
import sys
import threading
import time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
GIB = 1024 ** 3
MIB = 1024 ** 2


class Failure(Exception):
    pass


def find_root():
    """The folder holding tools/extractor.py and editor/extract.py: the repository, or an unpacked setup bundle."""
    for base in (ROOT, HERE):
        if (base / "tools" / "extractor.py").is_file() and (base / "editor" / "extract.py").is_file():
            return base
    raise Failure("tools/extractor.py and editor/extract.py are not here: run the setup from the OpenRAC folder or its setup bundle")


def run(command, say, cwd):
    """Runs a command, passing its output on line by line; a failure is the Failure of its last lines."""
    say("> " + " ".join(str(c) for c in command))
    process = subprocess.Popen(
        [str(c) for c in command], cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf8", errors="replace"
    )
    tail = []
    for line in process.stdout:
        line = line.rstrip()
        if line:
            say(line)
            tail = (tail + [line])[-6:]
    if process.wait() != 0:
        raise Failure("a step failed (exit %d):\n%s" % (process.returncode, "\n".join(tail)))


def copy_tree(source, target, say):
    count = 0
    for path in sorted(source.rglob("*")):
        if path.is_file():
            destination = target / path.relative_to(source)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, destination)
            count += 1
    say("copied %d file(s) to %s" % (count, target))


# ---------------------------------------------------------------------------------------------- FTP

class Ftp:
    """The console's FTP server: plain FTP, passive mode, uploads that resume."""

    def __init__(self, host, port, user, password, root, say):
        self.host, self.port, self.say = host, port, say
        self.user = user or "anonymous"
        self.password = password or "openrac@"
        self.root = "/" + root.strip("/") if root.strip("/") else ""
        self.f = None
        self.dirs = set()
        self.no_rest = False

    def connect(self):
        self.close()
        self.f = ftplib.FTP()
        self.f.encoding = "utf-8"
        self.f.connect(self.host, self.port, timeout=60)
        self.f.login(self.user, self.password)
        self.f.set_pasv(True)
        self.f.voidcmd("TYPE I")
        self.dirs = set()

    def close(self):
        if self.f is not None:
            try:
                self.f.close()
            except Exception:
                pass
            self.f = None

    def cd(self, remote_dir):
        """Makes remote_dir (under the root) and goes into it."""
        path = self.root + "/" + remote_dir.strip("/") if remote_dir.strip("/") else (self.root or "/")
        if path in self.dirs:
            self.f.cwd(path)
            return
        self.f.cwd("/")
        built = ""
        for part in [p for p in path.split("/") if p]:
            built += "/" + part
            try:
                self.f.cwd(built)
            except ftplib.error_perm:
                self.f.mkd(built)
                self.f.cwd(built)
        self.dirs.add(path)

    def size(self, name):
        try:
            return self.f.size(name)
        except ftplib.error_perm:
            return None

    def put_small(self, local, remote_dir, name):
        """A small file: one STOR with its whole path (no CWD, no SIZE before or after), the directory already made. Retried on a new connection."""
        path = self.root + "/" + remote_dir.strip("/") + "/" + name
        for attempt in range(1, 9):
            try:
                if self.f is None:
                    self.connect()
                with open(local, "rb") as fp:
                    self.f.storbinary("STOR " + path, fp, blocksize=256 * 1024)
                return
            except (ftplib.all_errors, OSError) as e:
                self.say("  %s: %s (try %d of 8)" % (name, e, attempt))
                self.close()
                time.sleep(min(2 * attempt, 10))
        raise Failure("could not send %s: the connection keeps failing" % name)

    def upload(self, local, remote_dir, name, label):
        total = local.stat().st_size
        last_said = [0.0]
        started = time.time()
        for attempt in range(1, 9):
            try:
                if self.f is None:
                    self.connect()
                self.cd(remote_dir)
                have = self.size(name)
                if have == total:
                    return "skipped"
                start = have if (have and 0 < have < total and not self.no_rest) else 0
                sent = [start]

                def progress(block):
                    sent[0] += len(block)
                    now = time.time()
                    if total > 64 * MIB and now - last_said[0] > 15:
                        last_said[0] = now
                        speed = (sent[0] - start) / max(now - started, 0.1) / MIB
                        self.say("  %s: %d%% (%.1f MB/s)" % (label, 100 * sent[0] // total, speed))

                with open(local, "rb") as fp:
                    fp.seek(start)
                    try:
                        self.f.storbinary("STOR " + name, fp, blocksize=256 * 1024, callback=progress, rest=start or None)
                    except ftplib.error_perm as e:
                        if start and str(e).startswith("5"):
                            # this server does not resume: from the start
                            self.no_rest = True
                            self.say("  the server does not resume an upload: sending %s again from the start" % label)
                            fp.seek(0)
                            sent[0] = 0
                            self.f.storbinary("STOR " + name, fp, blocksize=256 * 1024, callback=progress)
                        else:
                            raise
                after = self.size(name)
                if after is not None and after != total:
                    raise Failure("%s arrived as %d bytes, not %d" % (label, after, total))
                return "sent" if not start else "resumed"
            except (ftplib.all_errors, OSError) as e:
                self.say("  %s: %s (try %d of 8)" % (label, e, attempt))
                self.close()
                time.sleep(min(2 * attempt, 10))
        raise Failure("could not send %s: the connection keeps failing" % label)


def upload_tree(make_connection, local_root, say, connections=4):
    """Uploads switch/openrac of local_root to the console over several connections, as an FTP client does: the big files (the disc image) on one
    of them while the others send the many small ones (each small file costs several round trips on one connection, which is what makes a
    single-connection upload of thousands of files slow)."""
    base = local_root / "switch" / "openrac"
    files = [p for p in base.rglob("*") if p.is_file()]
    big = sorted((p for p in files if p.stat().st_size > 64 * MIB), key=lambda p: p.stat().st_size)
    small = sorted((p for p in files if p.stat().st_size <= 64 * MIB), key=lambda p: p.as_posix())
    total = sum(p.stat().st_size for p in files)
    say("sending %d file(s), %.2f GB, over %d connection(s)" % (len(files), total / GIB, max(1, connections)))

    # the folders first, on one connection
    first = make_connection()
    first.connect()
    for folder in sorted({p.relative_to(local_root).parent.as_posix() for p in files}):
        first.cd(folder)
    first.close()

    lock = threading.Lock()
    todo = queue.Queue()
    for path in small:
        todo.put(path)
    state = {"files": 0, "bytes": 0, "error": None}
    started = time.time()

    def note(path):
        with lock:
            state["files"] += 1
            state["bytes"] += path.stat().st_size
            if state["files"] % 500 == 0 or path in big:
                say("  [%d/%d] %.2f of %.2f GB, %.0f s" % (state["files"], len(files), state["bytes"] / GIB, total / GIB, time.time() - started))

    def small_worker():
        connection = make_connection()
        try:
            while state["error"] is None:
                try:
                    path = todo.get_nowait()
                except queue.Empty:
                    return
                folder, name = path.relative_to(local_root).as_posix().rsplit("/", 1)
                connection.put_small(path, folder, name)
                note(path)
        except Exception as e:
            state["error"] = e
        finally:
            connection.close()

    def big_worker():
        connection = make_connection()
        try:
            for path in big:
                if state["error"] is not None:
                    return
                relative = path.relative_to(local_root).as_posix()
                folder, name = relative.rsplit("/", 1)
                result = connection.upload(path, folder, name, relative)
                say("  %s %s" % (result, relative))
                note(path)
        except Exception as e:
            state["error"] = e
        finally:
            connection.close()

    threads = []
    if big:
        threads.append(threading.Thread(target=big_worker, daemon=True))
    for _ in range(max(1, connections - (1 if big else 0))):
        threads.append(threading.Thread(target=small_worker, daemon=True))
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    if state["error"] is not None:
        raise state["error"] if isinstance(state["error"], Failure) else Failure(str(state["error"]))
    say("sent %d file(s) in %.0f s" % (len(files), time.time() - started))


# ---------------------------------------------------------------------------------------------- the tree

def build_tree(iso, out_root, arsenal, bundle, say, jobs=None):
    """Writes switch/openrac of the game into out_root (an SD card's root, or a work folder)."""
    base = find_root()
    target = out_root / "switch" / "openrac"
    data = target / "data"
    target.mkdir(parents=True, exist_ok=True)

    say("== 1/4  the disc: checking it and writing the boot files and the image")
    run([sys.executable, base / "tools" / "extractor.py", "-g", "rac1", "--proj-path", data, "-e", "--boot-only", iso], say, base)

    say("== 2/4  the levels: exporting them from the disc (a few minutes)")
    command = [sys.executable, base / "editor" / "extract.py", "port", iso, data / "port" / "ntsc", "--anywhere"]
    if jobs:
        command += ["--jobs", str(jobs)]
    run(command, say, base)

    say("== 3/4  the program and its pictures")
    shutil.copy2(bundle / "openrac.nro", target / "openrac.nro")
    if (bundle / "texture_packs").is_dir():
        copy_tree(bundle / "texture_packs", data / "texture_packs", say)

    say("== 4/4  the optional mod")
    plugins = data / "plugins"
    if arsenal and (bundle / "mods" / "arsenal-mastery").is_dir():
        copy_tree(bundle / "mods" / "arsenal-mastery", plugins / "arsenal-mastery", say)
        (plugins / "plugins.json").write_text(
            json.dumps({"format": 1, "mods": [{"id": "arsenal-mastery", "enabled": True, "settings": {}}]}, indent=2) + "\n", encoding="utf8"
        )
        say("Arsenal Mastery is on: delete the folder plugins/arsenal-mastery, or set \"enabled\": false in plugins.json, to play the original game")
    elif arsenal:
        say("the bundle has no mods/arsenal-mastery: skipped")
    else:
        say("left out (the original game)")
    return target


def parse_ftp(text, port):
    host = text.strip()
    if host.count(":") == 1:
        host, p = host.split(":")
        port = int(p)
    return host, port


def install(iso, arsenal, bundle, say, sd=None, ftp=None, jobs=None, work=None, keep_work=False, connections=4):
    """sd: the SD card's root (a folder); ftp: (host, port, user, password, root). One of them."""
    iso = pathlib.Path(iso)
    bundle = pathlib.Path(bundle)
    if not iso.is_file():
        raise Failure("the disc image %s is not a file" % iso)
    if not (bundle / "openrac.nro").is_file():
        raise Failure("%s has no openrac.nro: the setup bundle is incomplete" % bundle)
    if (sd is None) == (ftp is None):
        raise Failure("choose the SD card or FTP")
    size = iso.stat().st_size
    if sd is not None:
        sd = pathlib.Path(sd)
        if not sd.is_dir():
            raise Failure("the SD card folder %s is not there" % sd)
        free = shutil.disk_usage(sd).free
        needed = size + int(1.5 * GIB)
        if free < needed:
            raise Failure("the SD card has %.1f GB free and the game needs %.1f GB (the disc image and the levels)" % (free / GIB, needed / GIB))
        if size > 4 * GIB - 1 and shutil.disk_usage(sd).total < 40 * GIB:
            say("warning: the image is over 4 GB: a card formatted FAT32 cannot hold it (format it exFAT)")
        target = build_tree(iso, sd, arsenal, bundle, say, jobs)
        say("")
        say("Done. Put the card in the console and start OpenRAC from the homebrew menu: %s" % (target / "openrac.nro"))
        return

    host, port, user, password, root = ftp
    # the console first: a wrong address is found before the long extraction
    say("== connecting to the console's FTP server at %s:%d" % (host, port))
    def make_connection():
        return Ftp(host, port, user, password, root, say)

    try:
        probe = make_connection()
        probe.connect()
        probe.close()
    except (ftplib.all_errors, OSError) as e:
        raise Failure("cannot reach the FTP server at %s:%d: %s\nStart an FTP server on the console and use the address and port it shows." % (host, port, e))
    work_dir = pathlib.Path(work) if work else iso.parent / "OpenRAC-Switch2-work"
    work_dir.mkdir(parents=True, exist_ok=True)
    free = shutil.disk_usage(work_dir).free
    if free < int(1.5 * GIB):
        raise Failure("the work folder %s has %.1f GB free: it needs about 1.5 GB (and %.1f GB more when it is not on the disc image's drive)" % (work_dir, free / GIB, size / GIB))
    try:
        build_tree(iso, work_dir, arsenal, bundle, say, jobs)
        say("== sending to the console")
        upload_tree(make_connection, work_dir, say, connections)
    finally:
        if not keep_work:
            shutil.rmtree(work_dir, ignore_errors=True)
    say("")
    say("Done. Start OpenRAC from the console's homebrew menu (switch/openrac/openrac.nro).")


# ---------------------------------------------------------------------------------------------- the front ends

def ask(question, default=""):
    reply = input("%s%s: " % (question, " [%s]" % default if default else "")).strip()
    return reply or default


def run_cli(args):
    try:
        if not args.iso:
            args.iso = ask("Path of your Ratchet & Clank disc image (.iso, NTSC-U)")
        if not args.sd and not args.ftp:
            choice = ask("Install to an SD card in this PC, or over FTP to the console? (sd/ftp)", "ftp").lower()
            if choice.startswith("s"):
                args.sd = ask("The SD card's drive or folder (for example E:\\ or /media/you/SD)")
            else:
                args.ftp = ask("The console's FTP address (for example 192.168.1.50:1337)")
                args.ftp_user = args.ftp_user or ask("FTP user (empty: none, as the Switch 2 FTP server wants)")
                args.ftp_password = args.ftp_password or ask("FTP password (empty: none)")
        if sys.stdin.isatty() and "--arsenal-mastery" not in sys.argv and ask("Install Arsenal Mastery, the optional mod? (y/n)", "n").lower().startswith("y"):
            args.arsenal_mastery = True
        ftp = None
        if args.ftp:
            host, port = parse_ftp(args.ftp, args.ftp_port)
            ftp = (host, port, args.ftp_user, args.ftp_password, args.ftp_root)
        install(args.iso, args.arsenal_mastery, args.bundle, print, sd=args.sd if not ftp else None, ftp=ftp, jobs=args.jobs, work=args.work, keep_work=args.keep_work, connections=args.ftp_connections)
    except Failure as e:
        print("error: %s" % e, file=sys.stderr)
        return 1
    return 0


def run_window(args):
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    window = tk.Tk()
    window.title("OpenRAC for Switch 2: setup")
    window.geometry("780x620")
    iso = tk.StringVar(value=args.iso or "")
    mode = tk.StringVar(value="sd" if args.sd else "ftp")
    sd = tk.StringVar(value=args.sd or "")
    host = tk.StringVar(value=args.ftp or "")
    port = tk.StringVar(value=str(args.ftp_port))
    user = tk.StringVar(value=args.ftp_user or "")
    password = tk.StringVar(value=args.ftp_password or "")
    root = tk.StringVar(value=args.ftp_root)
    arsenal = tk.BooleanVar(value=args.arsenal_mastery)
    lines = queue.Queue()
    busy = {"on": False}

    frame = ttk.Frame(window, padding=12)
    frame.pack(fill="both", expand=True)
    frame.columnconfigure(1, weight=1)
    ttk.Label(frame, text="Your Ratchet & Clank disc image (.iso, NTSC-U):").grid(row=0, column=0, columnspan=3, sticky="w")
    ttk.Entry(frame, textvariable=iso).grid(row=1, column=0, columnspan=2, sticky="ew", pady=(2, 10))
    ttk.Button(frame, text="Browse...", command=lambda: iso.set(filedialog.askopenfilename(filetypes=[("Disc image", "*.iso"), ("All files", "*.*")]) or iso.get())).grid(row=1, column=2, padx=(6, 0))

    ttk.Label(frame, text="Put the game on the console:").grid(row=2, column=0, columnspan=3, sticky="w")
    choices = ttk.Frame(frame)
    choices.grid(row=3, column=0, columnspan=3, sticky="w")
    ttk.Radiobutton(choices, text="Over FTP (the console on the network)", variable=mode, value="ftp").pack(side="left", padx=(0, 20))
    ttk.Radiobutton(choices, text="Onto an SD card in this PC", variable=mode, value="sd").pack(side="left")

    ftp_box = ttk.Frame(frame)
    sd_box = ttk.Frame(frame)
    ftp_box.grid(row=4, column=0, columnspan=3, sticky="ew", pady=8)
    sd_box.grid(row=4, column=0, columnspan=3, sticky="ew", pady=8)
    ftp_box.columnconfigure(1, weight=1)
    sd_box.columnconfigure(0, weight=1)
    ttk.Label(ftp_box, text="Console address:").grid(row=0, column=0, sticky="w")
    ttk.Entry(ftp_box, textvariable=host).grid(row=0, column=1, sticky="ew", padx=6)
    ttk.Label(ftp_box, text="Port:").grid(row=0, column=2, sticky="w")
    ttk.Entry(ftp_box, textvariable=port, width=7).grid(row=0, column=3, padx=6)
    ttk.Label(ftp_box, text="User:").grid(row=1, column=0, sticky="w", pady=4)
    ttk.Entry(ftp_box, textvariable=user).grid(row=1, column=1, sticky="ew", padx=6)
    ttk.Label(ftp_box, text="Password:").grid(row=1, column=2, sticky="w")
    ttk.Entry(ftp_box, textvariable=password, show="*", width=14).grid(row=1, column=3, padx=6)
    ttk.Label(ftp_box, text="SD card folder on the console:").grid(row=2, column=0, sticky="w")
    ttk.Entry(ftp_box, textvariable=root).grid(row=2, column=1, sticky="ew", padx=6)
    ttk.Label(ftp_box, text="Start the FTP server on the console and type its address (its default port is 1337, no user or password). About 5 GB are sent; it resumes if it stops.", foreground="gray").grid(row=3, column=0, columnspan=4, sticky="w", pady=(6, 0))
    ttk.Label(sd_box, text="The SD card (its drive or folder, the one with the switch folder):").grid(row=0, column=0, columnspan=2, sticky="w")
    ttk.Entry(sd_box, textvariable=sd).grid(row=1, column=0, sticky="ew", pady=2)
    ttk.Button(sd_box, text="Browse...", command=lambda: sd.set(filedialog.askdirectory() or sd.get())).grid(row=1, column=1, padx=(6, 0))

    def show(*_):
        (ftp_box if mode.get() == "ftp" else sd_box).tkraise()
        (sd_box if mode.get() == "ftp" else ftp_box).grid_remove()
        (ftp_box if mode.get() == "ftp" else sd_box).grid()

    mode.trace_add("write", show)
    show()

    ttk.Checkbutton(
        frame,
        text="Install Arsenal Mastery (an optional mod that adds weapon and health levels; leave it off for the original game)",
        variable=arsenal,
    ).grid(row=5, column=0, columnspan=3, sticky="w")
    button = ttk.Button(frame, text="Install")
    button.grid(row=6, column=0, columnspan=3, pady=10)
    bar = ttk.Progressbar(frame, mode="indeterminate")
    bar.grid(row=7, column=0, columnspan=3, sticky="ew")
    log = tk.Text(frame, height=14, wrap="word", state="disabled")
    log.grid(row=8, column=0, columnspan=3, sticky="nsew", pady=(10, 0))
    frame.rowconfigure(8, weight=1)

    def say(text):
        lines.put(text)

    def pump():
        while True:
            try:
                text = lines.get_nowait()
            except queue.Empty:
                break
            if text is None:
                busy["on"] = False
                bar.stop()
                button.config(state="normal")
                continue
            log.config(state="normal")
            log.insert("end", text + "\n")
            log.see("end")
            log.config(state="disabled")
        window.after(100, pump)

    def work():
        try:
            if mode.get() == "ftp":
                address, p = parse_ftp(host.get(), int(port.get() or 1337))
                install(iso.get(), arsenal.get(), args.bundle, say, ftp=(address, p, user.get(), password.get(), root.get()), jobs=args.jobs, work=args.work, keep_work=args.keep_work, connections=args.ftp_connections)
            else:
                install(iso.get(), arsenal.get(), args.bundle, say, sd=sd.get(), jobs=args.jobs)
        except Failure as e:
            say("")
            say("FAILED: %s" % e)
        except Exception as e:  # a bug of the setup's own: shown, not hidden
            say("")
            say("FAILED: %r" % e)
        finally:
            say(None)

    def start():
        if busy["on"]:
            return
        if not iso.get() or not (host.get() if mode.get() == "ftp" else sd.get()):
            messagebox.showinfo("OpenRAC setup", "Pick the disc image, and the console's address or the SD card, first.")
            return
        busy["on"] = True
        button.config(state="disabled")
        bar.start(12)
        threading.Thread(target=work, daemon=True).start()

    button.config(command=start)
    pump()
    window.mainloop()
    return 0


def main():
    ap = argparse.ArgumentParser(description="OpenRAC for the Nintendo Switch 2: puts the game on the console from your own disc image")
    ap.add_argument("--cli", action="store_true", help="no window: ask in the terminal for what is not given")
    ap.add_argument("--iso")
    ap.add_argument("--sd", help="the SD card's drive or folder (writes straight onto it)")
    ap.add_argument("--ftp", help="the console's FTP address, HOST or HOST:PORT (uploads over the network)")
    ap.add_argument("--ftp-port", type=int, default=1337)
    ap.add_argument("--ftp-user", default="")
    ap.add_argument("--ftp-password", default="")
    ap.add_argument("--ftp-root", default="/", help="the SD card's folder on the console's FTP server (default /)")
    ap.add_argument("--ftp-connections", type=int, default=4, help="connections to the console at once (default 4; 1 if its FTP server allows only one)")
    ap.add_argument("--work", help="the work folder of an FTP install (default: next to the disc image)")
    ap.add_argument("--keep-work", action="store_true", help="keep the work folder afterwards")
    ap.add_argument("--arsenal-mastery", action="store_true", help="also install the optional Arsenal Mastery mod")
    ap.add_argument("--bundle", default=str(HERE / "bundle"))
    ap.add_argument("--jobs", type=int, help="levels to export at once")
    args = ap.parse_args()
    if args.sd and args.ftp:
        ap.error("choose --sd or --ftp, not both")
    if not args.cli:
        try:
            import tkinter  # noqa: F401
        except ImportError:
            print("(no window here: python3-tk is not installed; asking in the terminal)")
            args.cli = True
    if args.cli:
        return run_cli(args)
    return run_window(args)


if __name__ == "__main__":
    sys.exit(main())
