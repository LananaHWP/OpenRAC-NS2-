#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""OpenRAC for the Nintendo Switch 2: puts the game on the console from the player's own disc image: onto an SD card in this PC, over FTP, or
into a folder on this PC to copy over yourself.

    python3 switch2_setup.py                       a window: pick the disc image, then where it goes (FTP, SD card, folder), and Install
    python3 switch2_setup.py --cli                 the same by questions in the terminal (no window needed)
    python3 switch2_setup.py --cli --iso GAME.iso --sd E:\\ [--arsenal-mastery] [--quickselect-pause] [--steady-strafe]
    python3 switch2_setup.py --cli --iso GAME.iso --ftp 192.168.1.50[:1337] [--ftp-user U --ftp-password P --ftp-root /]
    python3 switch2_setup.py --cli --iso GAME.iso --folder D:\\OpenRAC-out

The disc it knows (found from the boot file SYSTEM.CNF names): Ratchet & Clank, NTSC-U (SCUS_971.99). The table GAMES below is where another
game's program (its own folder under switch/) would be added.

What it does (everything goes to that folder of the card, nothing to the console's own storage):
  1. checks the image is a disc OpenRAC knows and there is room;
  2. writes the boot files and the disc image (the game reads most of its data from the disc by sector)  -> data/iso_data/<game>/
  3. exports the levels the renderer draws, from the disc                                                  -> data/port/<ntsc|pal>/
  4. copies the program (openrac.nro) and its pictures (the Switch button prompts, the help screen)
  5. optionally the mods (Arsenal Mastery, Quick Select pause, Steady strafe: each its own choice, off is the original game)  -> data/plugins/

To an SD card the files are written straight onto it. Into a folder, the same tree (switch/<folder of the game>/...) is written under the folder you
pick: copy its switch folder onto the card's root yourself (FileZilla, a card reader, a file manager). Over FTP they are made in a work folder next
to the disc image (about 1 GB; the image itself is linked, not copied, when that folder is on the same drive) and uploaded to the console's FTP
server (the homebrew FTP servers of the Switch: start one, note the address it shows). An upload that stops is resumed from where it was (run the
setup again). The work folder is deleted afterwards.

No part of the game is shipped: steps 2 and 3 read the player's own disc. Needs Python 3.9 or newer (the standard library only).
The bundle (the .nro programs, the pictures, the mod) is the folder `bundle` next to this file, or --bundle DIR.
"""
import argparse
import ftplib
import json
import pathlib
import queue
import re
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


# The discs the setup knows, by the serial of the boot file SYSTEM.CNF names. game: the extractor's game id, version: the folder of the exported
# levels, home: the program's folder under switch/ on the card (the same as OPENRAC_SWITCH2_HOME of its build), nro: its file in the bundle.
GAMES = {
    "SCUS_971.99": {
        "title": "Ratchet & Clank (NTSC-U)", "game": "rac1", "version": "ntsc", "home": "openrac", "nro": "openrac.nro",
        "pictures": True, "mod": True,
    },
}


# The optional mods the bundle may hold (bundle/mods/<id>), each its own choice: copied to data/plugins/<id> and switched on in plugins.json.
# flag: its command line switch; about: the line the window and the terminal show beside it.
MODS = [
    {"id": "arsenal-mastery", "name": "Arsenal Mastery", "flag": "--arsenal-mastery",
     "about": "weapon and health levels as in Ratchet & Clank 3 (from rac-rs)"},
    {"id": "quickselect-pause", "name": "Quick Select pause", "flag": "--quickselect-pause",
     "about": "the world stands still while the Quick Select ring is up"},
    {"id": "steady-strafe", "name": "Steady strafe", "flag": "--steady-strafe",
     "about": "hold R2 to strafe facing the camera, as in Ratchet & Clank 2"},
]


def selected_mods(args):
    """The ids the command line asked for: --mods ID,ID, and each mod's own flag."""
    ids = [m.strip() for m in (args.mods or "").split(",") if m.strip()]
    for mod in MODS:
        if getattr(args, mod["id"].replace("-", "_"), False) and mod["id"] not in ids:
            ids.append(mod["id"])
    return ids


def identify(iso):
    """The GAMES entry of a disc image: the serial its SYSTEM.CNF boots (that file is among the first sectors of the image)."""
    with open(iso, "rb") as fp:
        head = fp.read(128 * MIB)
    match = re.search(rb"BOOT2\s*=\s*cdrom0:\\?([A-Z]{4}_[0-9]{3}\.[0-9]{2})", head)
    if match is None:
        raise Failure("%s is not a PlayStation 2 disc image (no SYSTEM.CNF with a BOOT2 line)" % iso)
    serial = match.group(1).decode("ascii")
    if serial not in GAMES:
        known = ", ".join("%s (%s)" % (g["title"], s) for s, g in GAMES.items())
        raise Failure("this disc (%s) is not one OpenRAC runs on the Switch 2 yet. Known: %s" % (serial, known))
    return GAMES[serial]


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


def upload_tree(make_connection, local_root, home, say, connections=4):
    """Uploads switch/<home> of local_root to the console over several connections, as an FTP client does: the big files (the disc image) on one
    of them while the others send the many small ones (each small file costs several round trips on one connection, which is what makes a
    single-connection upload of thousands of files slow)."""
    base = local_root / "switch" / home
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

def build_tree(profile, iso, out_root, mods, bundle, say, jobs=None):
    """Writes switch/<the game's folder> into out_root (an SD card's root, a folder for the player to copy, or a work folder)."""
    base = find_root()
    target = out_root / "switch" / profile["home"]
    data = target / "data"
    target.mkdir(parents=True, exist_ok=True)

    say("== 1/4  the disc: checking it and writing the boot files and the image")
    run([sys.executable, base / "tools" / "extractor.py", "-g", profile["game"], "--proj-path", data, "-e", "--boot-only", iso], say, base)

    say("== 2/4  the levels: exporting them from the disc (a few minutes)")
    command = [sys.executable, base / "editor" / "extract.py", "port", iso, data / "port" / profile["version"], "--anywhere"]
    if jobs:
        command += ["--jobs", str(jobs)]
    run(command, say, base)

    say("== 3/4  the program" + (" and its pictures" if profile["pictures"] else ""))
    shutil.copy2(bundle / profile["nro"], target / profile["nro"])
    if profile["pictures"] and (bundle / "texture_packs").is_dir():
        copy_tree(bundle / "texture_packs", data / "texture_packs", say)

    say("== 4/4  the optional mods")
    plugins = data / "plugins"
    chosen = []
    if not profile["mod"]:
        say("none for this game")
    else:
        for mod in MODS:
            if mod["id"] not in mods:
                continue
            if (bundle / "mods" / mod["id"]).is_dir():
                copy_tree(bundle / "mods" / mod["id"], plugins / mod["id"], say)
                chosen.append(mod)
                say("%s is on" % mod["name"])
            else:
                say("the bundle has no mods/%s: %s skipped" % (mod["id"], mod["name"]))
        if chosen:
            (plugins / "plugins.json").write_text(
                json.dumps({"format": 1, "mods": [{"id": m["id"], "enabled": True, "settings": {}} for m in chosen]}, indent=2) + "\n", encoding="utf8"
            )
            say("Each mod can be turned off later: delete its folder in plugins, or set enabled to false in plugins.json")
        else:
            say("left out (the original game)")
    return target


def parse_ftp(text, port):
    host = text.strip()
    if host.count(":") == 1:
        host, p = host.split(":")
        port = int(p)
    return host, port


def install(iso, mods, bundle, say, sd=None, ftp=None, folder=None, jobs=None, work=None, keep_work=False, connections=4):
    """sd: the SD card's root (a folder); ftp: (host, port, user, password, root); folder: a folder on this PC to write the card's tree into. One of them."""
    iso = pathlib.Path(iso)
    bundle = pathlib.Path(bundle)
    if not iso.is_file():
        raise Failure("the disc image %s is not a file" % iso)
    profile = identify(iso)
    say("disc: %s" % profile["title"])
    if not (bundle / profile["nro"]).is_file():
        raise Failure("%s has no %s: the setup bundle is incomplete (or has no program for this game)" % (bundle, profile["nro"]))
    if [sd is not None, ftp is not None, folder is not None].count(True) != 1:
        raise Failure("choose the SD card, FTP or a folder")
    size = iso.stat().st_size
    needed = size + int(1.5 * GIB)
    if sd is not None or folder is not None:
        out = pathlib.Path(sd if sd is not None else folder)
        if sd is not None and not out.is_dir():
            raise Failure("the SD card folder %s is not there" % out)
        if folder is not None:
            out.mkdir(parents=True, exist_ok=True)
        free = shutil.disk_usage(out).free
        if free < needed:
            raise Failure("%s has %.1f GB free and the game needs %.1f GB (the disc image and the levels)" % (out, free / GIB, needed / GIB))
        if sd is not None and size > 4 * GIB - 1 and shutil.disk_usage(out).total < 40 * GIB:
            say("warning: the image is over 4 GB: a card formatted FAT32 cannot hold it (format it exFAT)")
        target = build_tree(profile, iso, out, mods, bundle, say, jobs)
        say("")
        if sd is not None:
            say("Done. Put the card in the console and start the game from the homebrew menu: %s" % (target / profile["nro"]))
        else:
            say("Done. Copy the folder %s onto the SD card's root (so that it ends up as switch/%s on the card), over FTP or with a card reader." % (out / "switch", profile["home"]))
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
        build_tree(profile, iso, work_dir, mods, bundle, say, jobs)
        say("== sending to the console")
        upload_tree(make_connection, work_dir, profile["home"], say, connections)
    finally:
        if not keep_work:
            shutil.rmtree(work_dir, ignore_errors=True)
    say("")
    say("Done. Start the game from the console's homebrew menu (switch/%s/%s)." % (profile["home"], profile["nro"]))


# ---------------------------------------------------------------------------------------------- the front ends

def ask(question, default=""):
    try:
        reply = input("%s%s: " % (question, " [%s]" % default if default else "")).strip()
    except EOFError:  # nothing to read from (piped input, a script): the default
        reply = ""
    return reply or default


def run_cli(args):
    try:
        if not args.iso:
            args.iso = ask("Path of your Ratchet & Clank disc image (.iso, NTSC-U)")
        profile = identify(args.iso) if pathlib.Path(args.iso).is_file() else None
        if not args.sd and not args.ftp and not args.folder:
            choice = ask("Install over FTP to the console, to an SD card in this PC, or into a folder on this PC? (ftp/sd/folder)", "ftp").lower()
            if choice.startswith("fo"):
                args.folder = ask("The folder to write to (a switch folder is made inside it)")
            elif choice.startswith("s"):
                args.sd = ask("The SD card's drive or folder (for example E:\\ or /media/you/SD)")
            else:
                args.ftp = ask("The console's FTP address (for example 192.168.1.50:1337)")
                args.ftp_user = args.ftp_user or ask("FTP user (empty: none, as the Switch 2 FTP server wants)")
                args.ftp_password = args.ftp_password or ask("FTP password (empty: none)")
        mods = selected_mods(args)
        if profile is not None and profile["mod"] and sys.stdin.isatty() and not mods:
            # no mod asked for on the command line: each is asked about, off by default
            for mod in MODS:
                if ask("Install %s (%s)? (y/n)" % (mod["name"], mod["about"]), "n").lower().startswith("y"):
                    mods.append(mod["id"])
        ftp = None
        if args.ftp:
            host, port = parse_ftp(args.ftp, args.ftp_port)
            ftp = (host, port, args.ftp_user, args.ftp_password, args.ftp_root)
        install(args.iso, mods, args.bundle, print, sd=args.sd if not ftp else None, ftp=ftp, folder=args.folder if not ftp and not args.sd else None, jobs=args.jobs, work=args.work, keep_work=args.keep_work, connections=args.ftp_connections)
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
    mode = tk.StringVar(value="sd" if args.sd else "folder" if args.folder else "ftp")
    sd = tk.StringVar(value=args.sd or "")
    folder = tk.StringVar(value=args.folder or "")
    host = tk.StringVar(value=args.ftp or "")
    port = tk.StringVar(value=str(args.ftp_port))
    user = tk.StringVar(value=args.ftp_user or "")
    password = tk.StringVar(value=args.ftp_password or "")
    root = tk.StringVar(value=args.ftp_root)
    asked = selected_mods(args)
    mod_vars = [(mod, tk.BooleanVar(value=mod["id"] in asked)) for mod in MODS]
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
    ttk.Radiobutton(choices, text="Onto an SD card in this PC", variable=mode, value="sd").pack(side="left", padx=(0, 20))
    ttk.Radiobutton(choices, text="Into a folder on this PC", variable=mode, value="folder").pack(side="left")

    ftp_box = ttk.Frame(frame)
    sd_box = ttk.Frame(frame)
    folder_box = ttk.Frame(frame)
    ftp_box.grid(row=4, column=0, columnspan=3, sticky="ew", pady=8)
    sd_box.grid(row=4, column=0, columnspan=3, sticky="ew", pady=8)
    folder_box.grid(row=4, column=0, columnspan=3, sticky="ew", pady=8)
    ftp_box.columnconfigure(1, weight=1)
    sd_box.columnconfigure(0, weight=1)
    folder_box.columnconfigure(0, weight=1)
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

    ttk.Label(folder_box, text="The folder to write to (a switch folder is made inside it; copy that onto the SD card's root yourself):").grid(row=0, column=0, columnspan=2, sticky="w")
    ttk.Entry(folder_box, textvariable=folder).grid(row=1, column=0, sticky="ew", pady=2)
    ttk.Button(folder_box, text="Browse...", command=lambda: folder.set(filedialog.askdirectory(mustexist=False) or folder.get())).grid(row=1, column=1, padx=(6, 0))

    def show(*_):
        boxes = {"ftp": ftp_box, "sd": sd_box, "folder": folder_box}
        for name, box in boxes.items():
            if name != mode.get():
                box.grid_remove()
        boxes[mode.get()].grid()
        boxes[mode.get()].tkraise()

    mode.trace_add("write", show)
    show()

    mods_box = ttk.LabelFrame(frame, text="Optional mods (all off is the original game; each can be turned off later)")
    mods_box.grid(row=5, column=0, columnspan=3, sticky="ew", pady=(0, 4))
    for mod, var in mod_vars:
        ttk.Checkbutton(mods_box, text="%s: %s" % (mod["name"], mod["about"]), variable=var).pack(anchor="w", padx=6)

    def chosen_mods():
        return [mod["id"] for mod, var in mod_vars if var.get()]

    button = ttk.Button(frame, text="Install")
    button.grid(row=6, column=0, columnspan=3, pady=10)
    bar = ttk.Progressbar(frame, mode="indeterminate")
    bar.grid(row=7, column=0, columnspan=3, sticky="ew")
    log = tk.Text(frame, height=12, wrap="word", state="disabled")
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
                install(iso.get(), chosen_mods(), args.bundle, say, ftp=(address, p, user.get(), password.get(), root.get()), jobs=args.jobs, work=args.work, keep_work=args.keep_work, connections=args.ftp_connections)
            else:
                if mode.get() == "folder":
                    install(iso.get(), chosen_mods(), args.bundle, say, folder=folder.get(), jobs=args.jobs)
                else:
                    install(iso.get(), chosen_mods(), args.bundle, say, sd=sd.get(), jobs=args.jobs)
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
        if not iso.get() or not {"ftp": host, "sd": sd, "folder": folder}[mode.get()].get():
            messagebox.showinfo("OpenRAC setup", "Pick the disc image, and the console's address, the SD card or the folder, first.")
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
    ap.add_argument("--folder", help="a folder on this PC: the card's switch/<game> tree is written into it, for you to copy onto the card")
    ap.add_argument("--ftp", help="the console's FTP address, HOST or HOST:PORT (uploads over the network)")
    ap.add_argument("--ftp-port", type=int, default=1337)
    ap.add_argument("--ftp-user", default="")
    ap.add_argument("--ftp-password", default="")
    ap.add_argument("--ftp-root", default="/", help="the SD card's folder on the console's FTP server (default /)")
    ap.add_argument("--ftp-connections", type=int, default=4, help="connections to the console at once (default 4; 1 if its FTP server allows only one)")
    ap.add_argument("--work", help="the work folder of an FTP install (default: next to the disc image)")
    ap.add_argument("--keep-work", action="store_true", help="keep the work folder afterwards")
    for mod in MODS:
        ap.add_argument(mod["flag"], action="store_true", help="also install the optional mod %s: %s" % (mod["name"], mod["about"]))
    ap.add_argument("--mods", help="optional mods to install, by id and separated by commas (%s)" % ",".join(m["id"] for m in MODS))
    ap.add_argument("--bundle", default=str(HERE / "bundle"))
    ap.add_argument("--jobs", type=int, help="levels to export at once")
    args = ap.parse_args()
    if [bool(args.sd), bool(args.ftp), bool(args.folder)].count(True) > 1:
        ap.error("choose one of --sd, --ftp and --folder")
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
