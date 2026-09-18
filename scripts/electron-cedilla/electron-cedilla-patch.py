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

    total_old = sum(data.count(old) for _, old, _ in PATCHES)
    if total_old == 0:
        patched_new = sum(data.count(new) for _, _, new in PATCHES)
        if patched_new > 0:
            print("[ok] already patched (nothing to do).")
            return 0
        print("[warn] pattern not found — the compose table format may have "
              "changed in this Chromium version. Please check upstream.",
              file=sys.stderr)
        return 2

    new_data = data
    report = []
    for desc, old, new in PATCHES:
        n = new_data.count(old)
        new_data = new_data.replace(old, new)
        report.append(f"  {desc}: {n} occurrence(s) replaced")

    # keep a pristine .orig once, plus a timestamped backup each run
    ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    if not os.path.exists(BIN + ".orig"):
        shutil.copy2(BIN, BIN + ".orig")
        print(f"[backup] pristine original saved to {BIN}.orig")
    shutil.copy2(BIN, f"{BIN}.bak-{ts}")

    with open(BIN, "r+b") as f:
        f.write(new_data)
        f.truncate(len(new_data))

    print("[ok] patch applied:")
    print("\n".join(report))
    print("Restart Electron apps (e.g. VS Code) completely and test ' + c.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
