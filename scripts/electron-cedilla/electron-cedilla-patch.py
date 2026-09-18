#!/usr/bin/env python3
"""
Patch the Electron binary so that ' + c produces ç (and ' + C -> Ç) on Wayland.

Adapted from chromium-wayland-cedilla-fix (chromium-cedilla-patch.py) for
Arch Linux's system Electron packages (e.g. electron42), used by
visual-studio-code-electron-bin. Same byte-pattern approach: on native
Wayland, Chromium/Electron uses ui::CharacterComposer with a compose table
compiled into the binary, ignoring ~/.XCompose. This changes ONLY the output
of dead_acute + c / C:

  c (0x0063) -> ć (0x0107):  63 00 07 01  =>  63 00 e7 00  (ç U+00E7)
  C (0x0043) -> Ć (0x0106):  43 00 06 01  =>  43 00 c7 00  (Ç U+00C7)

Idempotent. Makes a backup before writing. Needs write permission on the
binary (run with sudo).

Usage:
  sudo python3 electron-cedilla-patch.py [/path/to/electron]

Default path: /usr/lib/electron42/electron
"""
import sys, os, shutil, datetime

BIN = sys.argv[1] if len(sys.argv) > 1 else "/usr/lib/electron42/electron"

# (description, old pattern, new pattern)
PATCHES = [
    ("c -> ç", b"\x63\x00\x07\x01", b"\x63\x00\xe7\x00"),
    ("C -> Ç", b"\x43\x00\x06\x01", b"\x43\x00\xc7\x00"),
]

def main():
    if not os.path.isfile(BIN):
        print(f"[error] binary not found: {BIN}", file=sys.stderr)
        return 1

    data = open(BIN, "rb").read()

    counts = {desc: data.count(old) for desc, old, _ in PATCHES}
    total_old = sum(counts.values())
    if total_old == 0:
        new_counts = {desc: data.count(new) for desc, _, new in PATCHES}
        if all(n > 0 for n in new_counts.values()):
            print("[ok] already patched (nothing to do).")
            return 0
        print("[note] no compose-table patch target found. The binary either "
              "already ships c -> ç upstream or the compose table layout "
              "changed. Nothing to do.")
        return 2
    # the two entries belong to the same compose table set — a one-sided
    # match means the table layout changed and the 4-byte patterns may hit
    # unrelated data, so refuse to patch instead of guessing
    if any(n == 0 for n in counts.values()):
        for desc, n in counts.items():
            print(f"[err] {desc}: found {n} occurrence(s)", file=sys.stderr)
        print("[error] asymmetric pattern match; refusing to patch.",
              file=sys.stderr)
        return 3

    new_data = data
    report = []
    for desc, old, new in PATCHES:
        n = new_data.count(old)
        new_data = new_data.replace(old, new)
        report.append(f"  {desc}: {n} occurrence(s) replaced")

    # keep a pristine .orig once (per installed version — recreated if the
    # binary changed since, e.g. after a package upgrade), plus a timestamped
    # backup of the CURRENT binary before every patch run
    ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    shutil.copy2(BIN, f"{BIN}.bak-{ts}")
    try:
        if os.path.exists(BIN + ".orig"):
            with open(BIN + ".orig", "rb") as f_orig, open(BIN, "rb") as f_cur:
                differs = f_orig.read() != f_cur.read()
        else:
            differs = True
    except OSError:
        differs = False
    if differs:
        shutil.copy2(BIN, BIN + ".orig")
        print(f"[backup] pristine original of this version saved to {BIN}.orig")

    # write defensively instead of re-truncating in place: same target bytes,
    # but a mid-write failure can't leave a half-patched binary behind
    tmp = BIN + ".patched-tmp"
    with open(tmp, "wb") as f_tmp:
        f_tmp.write(new_data)
        f_tmp.flush()
        os.fsync(f_tmp.fileno())
    st = os.stat(BIN)
    os.chmod(tmp, st.st_mode & 0o777)
    # preserve ownership too (root:root)
    os.chown(tmp, st.st_uid, st.st_gid)
    os.replace(tmp, BIN)

    print("[ok] patch applied:")
    print("\n".join(report))
    print("Restart Electron apps (e.g. VS Code) completely and test ' + c.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
